import SwiftUI

struct PrayerCalendarView: View {
    @StateObject private var viewModel = PrayerCalendarViewModel()
    @State private var showingDayDetail = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {

                // Stats — vibrant game-style tiles (matches list cards / tree).
                HStack(spacing: AppSpacing.md) {
                    streakStatCard
                    totalStatCard
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.sm)

                // Month navigation — dark panel like the stats banner / tab bar.
                monthNavigationPanel
                    .padding(.horizontal, AppSpacing.lg)

                calendarGrid
                    .padding(.horizontal, AppSpacing.lg)

                legendRow
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xl)
            }
        }
        .background(gameBackground.ignoresSafeArea())
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarPlainBackButton()
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(gameBackground, for: .navigationBar)
        .tint(Color.appPrimary)
        .sheet(isPresented: $showingDayDetail) {
            if let record = viewModel.selectedDay {
                DayDetailSheet(
                    record: record,
                    sessions: viewModel.selectedDaySessions,
                    onDismiss: {
                        showingDayDetail = false
                        viewModel.deselectDay()
                    }
                )
                .presentationDetents([.medium, .large])
            }
        }
        .onAppear { viewModel.fetchRecords() }
        .onReceive(
            NotificationCenter.default.publisher(
                for: .NSManagedObjectContextDidSave,
                object: PersistenceController.shared.viewContext
            )
        ) { _ in
            viewModel.fetchRecords()
            if showingDayDetail {
                viewModel.refreshSelectedDaySessions()
            }
        }
    }

    // MARK: - Background

    private var gameBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.98, blue: 0.96),
                Color.appBackground,
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Stats Cards

    private var streakStatCard: some View {
        VStack(spacing: AppSpacing.xs) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.25))
                Image(systemName: "flame.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 52, height: 52)

            Text("\(viewModel.streakCount)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Day Streak")
                .font(AppFont.caption())
                .fontWeight(.semibold)
                .foregroundColor(Color.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
        .padding(.horizontal, AppSpacing.sm)
        .gameCardStyle(color: Color(red: 1.0, green: 0.48, blue: 0.35))
    }

    private var totalStatCard: some View {
        VStack(spacing: AppSpacing.xs) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.25))
                Image("prayingHands")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(.white)
            }
            .frame(width: 52, height: 52)

            Text("\(viewModel.totalSessionCount)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Sessions")
                .font(AppFont.caption())
                .fontWeight(.semibold)
                .foregroundColor(Color.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
        .padding(.horizontal, AppSpacing.sm)
        .gameCardStyle(color: Color.appGameXPFill)
    }

    // MARK: - Month Navigation

    private var monthNavigationPanel: some View {
        HStack(spacing: AppSpacing.sm) {
            monthChevronButton(systemName: "chevron.left", action: viewModel.previousMonth)

            Spacer(minLength: 0)

            Text(viewModel.monthTitle)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 0)

            monthChevronButton(systemName: "chevron.right", action: viewModel.nextMonth)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .gameDarkPanel(radius: AppRadius.xl)
    }

    private func monthChevronButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(
                    Circle().fill(Color.white.opacity(0.14))
                )
                .overlay(
                    Circle().strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let grid = viewModel.calendarGrid
        let columns = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.xs), count: 7)
        let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

        return VStack(spacing: AppSpacing.sm) {
            HStack(spacing: 0) {
                ForEach(weekdays.indices, id: \.self) { i in
                    Text(weekdays[i])
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color.appTextSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: AppSpacing.xs) {
                ForEach(grid.indices, id: \.self) { i in
                    let (day, record) = grid[i]
                    if day == 0 {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                    } else {
                        dayCell(day: day, record: record)
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 14, y: 6)
    }

    private func dayCell(day: Int, record: DailyRecord?) -> some View {
        let hasFootprint = record?.hasFootprint ?? false
        let isToday = isCurrentDay(day)
        let hasAnswered = (record?.sessionList.flatMap { $0.itemList }.contains { $0.statusEnum == .answered }) ?? false

        return Button {
            if let record {
                viewModel.selectDay(record)
                showingDayDetail = true
            }
        } label: {
            ZStack {
                dayCircleFill(hasAnswered: hasAnswered, hasFootprint: hasFootprint)

                if isToday {
                    Circle()
                        .strokeBorder(Color.appGameGold, lineWidth: 3)
                }

                VStack(spacing: 1) {
                    Text("\(day)")
                        .font(.system(size: 12, weight: hasFootprint || hasAnswered ? .bold : .medium, design: .rounded))
                        .foregroundColor(
                            (hasFootprint || hasAnswered) ? .white : Color.appTextPrimary
                        )

                    if hasFootprint {
                        Image(systemName: AppIcons.footprint)
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .disabled(record == nil)
        .buttonStyle(CalendarDayButtonStyle())
    }

    @ViewBuilder
    private func dayCircleFill(hasAnswered: Bool, hasFootprint: Bool) -> some View {
        if hasAnswered {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appGameGold,
                            Color(red: 0.95, green: 0.68, blue: 0.22),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.appGameGold.opacity(0.35), radius: 3, y: 1)
        } else if hasFootprint {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.appGameXPFill, Color.appPrimary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.appGameXPFill.opacity(0.3), radius: 3, y: 1)
        } else {
            Circle()
                .fill(Color.appSurfaceSecond)
        }
    }

    // MARK: - Legend

    private var legendRow: some View {
        HStack(spacing: AppSpacing.xs) {
            legendPill(dot: { legendDotPrayed() }, label: "Prayed")
            legendPill(dot: { legendDotNoRecord() }, label: "No record")
            legendPill(dot: { legendDotAnswered() }, label: "Answered")
        }
        .frame(maxWidth: .infinity)
    }

    private func legendPill<Dot: View>(@ViewBuilder dot: () -> Dot, label: String) -> some View {
        HStack(spacing: 6) {
            dot()
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(Color.appTextSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(Color.white)
        )
        .overlay(
            Capsule().strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private func legendDotPrayed() -> some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color.appGameXPFill, Color.appPrimary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 12, height: 12)
            .overlay(Circle().strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5))
    }

    private func legendDotNoRecord() -> some View {
        Circle()
            .fill(Color.appSurfaceSecond)
            .frame(width: 12, height: 12)
            .overlay(Circle().strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5))
    }

    private func legendDotAnswered() -> some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.appGameGold,
                        Color(red: 0.95, green: 0.68, blue: 0.22),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 12, height: 12)
            .overlay(Circle().strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5))
    }

    // MARK: - Helpers

    private func isCurrentDay(_ day: Int) -> Bool {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: viewModel.currentMonth)
        var dayComps = comps
        dayComps.day = day
        if let date = calendar.date(from: dayComps) {
            return calendar.isDateInToday(date)
        }
        return false
    }
}

// MARK: - Button Style

/// Slight scale on tap so day cells feel tactile like game tiles.
private struct CalendarDayButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        PrayerCalendarView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}

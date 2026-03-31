import SwiftUI

struct PrayerCalendarView: View {
    @StateObject private var viewModel = PrayerCalendarViewModel()
    @State private var showingDayDetail = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {

                // Stats header
                HStack(spacing: AppSpacing.md) {
                    streakCard
                    totalCard
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)

                // Month navigation
                HStack {
                    Button { viewModel.previousMonth() } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color.appPrimary)
                            .font(.system(size: 18, weight: .semibold))
                    }

                    Spacer()

                    Text(viewModel.monthTitle)
                        .font(AppFont.headline())
                        .foregroundColor(Color.appTextPrimary)

                    Spacer()

                    Button { viewModel.nextMonth() } label: {
                        Image(systemName: "chevron.right")
                            .foregroundColor(Color.appPrimary)
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
                .padding(.horizontal, AppSpacing.lg)

                // Calendar grid
                calendarGrid
                    .padding(.horizontal, AppSpacing.lg)

                // Legend
                HStack(spacing: AppSpacing.lg) {
                    legendItem(color: Color.appPrimary, label: "Prayed")
                    legendItem(color: Color.appSurfaceSecond, label: "No Record")
                    legendItem(color: Color.appAnswered, label: "Answered")
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Prayer Calendar")
        .navigationBarTitleDisplayMode(.inline)
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
    }

    // MARK: - Stats Cards

    private var streakCard: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: "flame.fill")
                .font(.system(size: 28))
                .foregroundColor(.orange)
            Text("\(viewModel.streakCount)")
                .font(AppFont.title())
                .foregroundColor(Color.appTextPrimary)
            Text("Day Streak")
                .font(AppFont.caption())
                .foregroundColor(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.lg)
        .cardStyle()
    }

    private var totalCard: some View {
        VStack(spacing: AppSpacing.xs) {
            Image("prayingHands")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .foregroundColor(Color.appPrimary)
            Text("\(viewModel.totalSessionCount)")
                .font(AppFont.title())
                .foregroundColor(Color.appTextPrimary)
            Text("Total Sessions")
                .font(AppFont.caption())
                .foregroundColor(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.lg)
        .cardStyle()
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let grid = viewModel.calendarGrid
        let columns = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.xs), count: 7)
        let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

        return VStack(spacing: AppSpacing.xs) {
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekdays.indices, id: \.self) { i in
                    Text(weekdays[i])
                        .font(AppFont.caption2())
                        .foregroundColor(Color.appTextTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day cells
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
        .background(Color.appSurface)
        .cornerRadius(AppRadius.xl)
        .shadow(color: AppShadow.cardShadow.color, radius: AppShadow.cardShadow.radius,
                x: AppShadow.cardShadow.x, y: AppShadow.cardShadow.y)
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
                Circle()
                    .fill(hasAnswered ? Color.appAnswered :
                          hasFootprint ? Color.appPrimary :
                          Color.appSurfaceSecond)

                if isToday {
                    Circle()
                        .stroke(Color.appAccent, lineWidth: 2)
                }

                VStack(spacing: 0) {
                    Text("\(day)")
                        .font(AppFont.caption())
                        .fontWeight(hasFootprint ? .semibold : .regular)
                        .foregroundColor(hasFootprint ? .white : Color.appTextPrimary)

                    if hasFootprint {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 7))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .disabled(record == nil)
        .buttonStyle(.plain)
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

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: AppSpacing.xxs) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(AppFont.caption2())
                .foregroundColor(Color.appTextTertiary)
        }
    }
}

#Preview {
    NavigationStack {
        PrayerCalendarView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}

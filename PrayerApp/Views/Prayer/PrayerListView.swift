import SwiftUI
import CoreData

struct PrayerListView: View {
    @StateObject private var viewModel = PrayerListViewModel()
    @StateObject private var sessionVM = PrayerSessionViewModel()

    @State private var showingAddPrayer = false
    @State private var showingSearch = false
    @State private var showingSession = false
    @State private var pendingDeletePrayerID: NSManagedObjectID?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    prayersHeader

                    // Custom segmented pill — game-style.
                    GameSegmentedPicker(
                        selection: $viewModel.selectedTab,
                        options: ListTab.allCases,
                        label: \.rawValue
                    )
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.xs)
                    .padding(.bottom, AppSpacing.sm)
                    .onChange(of: viewModel.selectedTab) { _ in viewModel.fetchPrayers() }

                    categoryFilterBar

                    if viewModel.prayers.isEmpty {
                        EmptyStateView(
                            iconName: AppIcons.prayers,
                            isAssetImage: true,
                            title: "No Prayers",
                            message: viewModel.selectedTab == .today
                                ? "Add a prayer to begin today's journey."
                                : "No prayers this month yet.",
                            actionTitle: "Add Prayer",
                            action: { showingAddPrayer = true }
                        )
                    } else {
                        prayerList
                    }
                }

                if viewModel.isSelectMode && !viewModel.selectedPrayers.isEmpty {
                    startPrayingFloatingButton
                }
            }
            .background(gameBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .deletePrayerConfirmation(pendingID: $pendingDeletePrayerID) { prayer in
            viewModel.deletePrayer(prayer)
        }
        .onAppear { viewModel.fetchPrayers() }
        .onReceive(
            NotificationCenter.default.publisher(
                for: .NSManagedObjectContextDidSave,
                object: PersistenceController.shared.viewContext
            )
        ) { _ in
            viewModel.fetchPrayers()
        }
        .sheet(isPresented: $showingAddPrayer, onDismiss: {
            viewModel.fetchPrayers()
        }) {
            AddPrayerView(startWithCaptureForm: true)
        }
        .fullScreenCover(isPresented: $showingSession) {
            if sessionVM.isFinished, let session = sessionVM.finishedSession {
                SessionCompleteView(
                    session: session,
                    newlyUnlocked: sessionVM.newlyAvailableDecorations,
                    onDismiss: { showingSession = false; sessionVM.reset() }
                )
            } else {
                PrayerSessionView(viewModel: sessionVM, onDismiss: {
                    showingSession = false; sessionVM.reset()
                })
            }
        }
    }

    // MARK: - Header

    private var prayersHeader: some View {
        HStack(alignment: .center, spacing: AppSpacing.sm) {
            Button {
                viewModel.isSelectMode.toggle()
                if !viewModel.isSelectMode { viewModel.clearSelection() }
            } label: {
                Text(viewModel.isSelectMode ? "Cancel" : "Select")
                    .font(AppFont.subheadline())
                    .fontWeight(.semibold)
                    .foregroundColor(Color.appPrimary)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(Color.white)
                    )
                    .overlay(
                        Capsule().strokeBorder(Color.appPrimary.opacity(0.25), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Prayers")
                .font(AppFont.largeTitle())
                .foregroundColor(Color.appTextPrimary)

            Spacer()

            headerIconButton(systemName: "calendar", destination: AnyView(PrayerCalendarView()))
            headerIconButton(systemName: AppIcons.search, destination: AnyView(PrayerSearchView()))
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.md)
        .padding(.bottom, AppSpacing.xs)
    }

    private func headerIconButton(systemName: String, destination: AnyView) -> some View {
        NavigationLink(destination: destination) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color.appPrimary)
                .frame(width: 36, height: 36)
                .background(
                    Circle().fill(Color.white)
                )
                .overlay(
                    Circle().strokeBorder(Color.appPrimary.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 3, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Filter Chips

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                GameFilterChip(
                    label: "All",
                    tint: Color.appPrimary,
                    isActive: viewModel.categoryFilter == nil
                ) {
                    viewModel.filterByCategory(nil)
                }
                ForEach(PrayerCategory.allCases, id: \.self) { cat in
                    GameFilterChip(
                        label: cat.displayName,
                        tint: cat.fallbackColor,
                        isActive: viewModel.categoryFilter == cat
                    ) {
                        viewModel.filterByCategory(cat)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.xxs)
        }
    }

    // MARK: - List

    private var prayerList: some View {
        List {
            ForEach(viewModel.prayers) { prayer in
                if viewModel.isSelectMode {
                    Button {
                        viewModel.toggleSelection(for: prayer)
                    } label: {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: viewModel.selectedPrayers.contains(prayer.objectID)
                                ? "checkmark.circle.fill"
                                : "circle")
                                .foregroundColor(Color.appPrimary)
                                .font(.system(size: 22))
                            PrayerCardView(
                                prayer: prayer,
                                isSelected: viewModel.selectedPrayers.contains(prayer.objectID)
                            )
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: AppSpacing.lg, bottom: 6, trailing: AppSpacing.lg))
                    .listRowSeparator(.hidden)
                } else {
                    ZStack {
                        NavigationLink(destination: PrayerDetailView(
                            prayer: prayer,
                            onStatusChange: { status in
                                viewModel.updateStatus(prayer, status: status)
                            },
                            onAddToToday: {
                                viewModel.addPersonalPrayerToToday(prayer)
                            }
                        )) { EmptyView() }
                            .opacity(0)

                        PrayerCardView(prayer: prayer)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: AppSpacing.lg, bottom: 6, trailing: AppSpacing.lg))
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            pendingDeletePrayerID = prayer.objectID
                        } label: {
                            Label("Delete", systemImage: AppIcons.delete)
                        }
                        .tint(.red)

                        if prayer.statusEnum != .archived {
                            Button {
                                viewModel.updateStatus(prayer, status: .archived)
                            } label: {
                                Label("Archive", systemImage: AppIcons.archive)
                            }
                            .tint(.gray)
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            viewModel.updateStatus(prayer, status: .prayed)
                        } label: {
                            Label("Mark Prayed", systemImage: AppIcons.prayed)
                        }
                        .tint(Color.appPrimary)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .safeAreaInset(edge: .bottom) {
            // Keep space below the floating tab bar + start button.
            Color.clear.frame(height: 100)
        }
    }

    private var startPrayingFloatingButton: some View {
        Button {
            let items = viewModel.selectedItems()
            sessionVM.startSession(items: items)
            viewModel.clearSelection()
            showingSession = true
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image("prayingHands")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                Text("Start Praying (\(viewModel.selectedPrayers.count))")
            }
        }
        .gameCTAButtonStyle(color: .appPrimary)
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, 100)   // Above the custom tab bar.
    }

    // Soft vertical gradient keeps the list feeling like a "page" in a game,
    // consistent with the Challenge and Tree tabs.
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
}

// MARK: - Shared Pickers

/// A pill-style segmented picker that matches the game-style cards.
/// Reusable across PrayerListView and IntercessoryListView.
struct GameSegmentedPicker<Option: Hashable>: View {
    @Binding var selection: Option
    let options: [Option]
    let label: (Option) -> String

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        selection = option
                    }
                } label: {
                    Text(label(option))
                        .font(AppFont.subheadline())
                        .fontWeight(.semibold)
                        .foregroundColor(selection == option ? .white : Color.appTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selection == option ? Color.appPrimary : Color.clear)
                                .shadow(
                                    color: selection == option ? Color.appPrimary.opacity(0.25) : .clear,
                                    radius: 4, y: 2
                                )
                        )
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Capsule().fill(Color.white)
        )
        .overlay(
            Capsule().strokeBorder(Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 6, y: 2)
    }
}

#Preview {
    PrayerListView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}

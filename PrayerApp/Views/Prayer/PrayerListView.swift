import SwiftUI

struct PrayerListView: View {
    @StateObject private var viewModel = PrayerListViewModel()
    @StateObject private var sessionVM = PrayerSessionViewModel()

    @State private var showingAddPrayer = false
    @State private var showingSearch = false
    @State private var showingSession = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("View", selection: $viewModel.selectedTab) {
                    ForEach(ListTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.sm)
                .onChange(of: viewModel.selectedTab) { _ in viewModel.fetchPrayers() }

                // Category Filter Bar
                categoryFilterBar

                // Content
                if viewModel.prayers.isEmpty {
                    EmptyStateView(
                        iconName: AppIcons.prayers,
                        isAssetImage: true,
                        title: "No Prayers",
                        message: viewModel.selectedTab == .today
                            ? "Add a prayer or start praying to see items here."
                            : "No prayers this month yet.",
                        actionTitle: "Add Prayer",
                        action: { showingAddPrayer = true }
                    )
                } else {
                    prayerList
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Prayers")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: PrayerSearchView()) {
                        Image(systemName: AppIcons.search)
                            .foregroundColor(Color.appPrimary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.isSelectMode.toggle()
                        if !viewModel.isSelectMode { viewModel.clearSelection() }
                    } label: {
                        Text(viewModel.isSelectMode ? "Cancel" : "Select")
                            .font(AppFont.subheadline())
                            .foregroundColor(Color.appPrimary)
                    }
                }
            }
        }
        .onAppear { viewModel.fetchPrayers() }
        .sheet(isPresented: $showingAddPrayer) { AddPrayerView() }
        .fullScreenCover(isPresented: $showingSession) {
            if sessionVM.isFinished, let session = sessionVM.finishedSession {
                SessionCompleteView(
                    session: session,
                    newlyUnlocked: sessionVM.newlyUnlockedDecorations,
                    onDismiss: { showingSession = false; sessionVM.reset() }
                )
            } else {
                PrayerSessionView(viewModel: sessionVM, onDismiss: {
                    showingSession = false; sessionVM.reset()
                })
            }
        }
    }

    // MARK: - Subviews

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                chipButton(label: "All", isActive: viewModel.categoryFilter == nil) {
                    viewModel.filterByCategory(nil)
                }
                ForEach(PrayerCategory.allCases, id: \.self) { cat in
                    chipButton(
                        label: cat.shortName,
                        color: cat.fallbackColor,
                        isActive: viewModel.categoryFilter == cat
                    ) {
                        viewModel.filterByCategory(cat)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.xs)
        }
    }

    private var prayerList: some View {
        ZStack(alignment: .bottom) {
            List {
                ForEach(viewModel.prayers) { prayer in
                    if viewModel.isSelectMode {
                        Button {
                            viewModel.toggleSelection(for: prayer)
                        } label: {
                            HStack {
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
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    } else {
                        NavigationLink(destination: PrayerDetailView(
                            prayer: prayer,
                            onStatusChange: { status in
                                viewModel.updateStatus(prayer, status: status)
                            }
                        )) {
                            PrayerCardView(prayer: prayer)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                viewModel.updateStatus(prayer, status: .answered)
                            } label: {
                                Label("Answered", systemImage: AppIcons.markAnswered)
                            }
                            .tint(.yellow)

                            Button {
                                viewModel.updateStatus(prayer, status: .archived)
                            } label: {
                                Label("Archive", systemImage: AppIcons.archive)
                            }
                            .tint(.gray)
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
            .background(Color.appBackground)

            // Start Praying button (shown in select mode with selection)
            if viewModel.isSelectMode && !viewModel.selectedPrayers.isEmpty {
                Button {
                    let items = viewModel.selectedItems()
                    sessionVM.startSession(items: items)
                    viewModel.clearSelection()
                    showingSession = true
                } label: {
                    Label("Start Praying (\(viewModel.selectedPrayers.count))", image: "prayingHands")
                }
                .primaryButtonStyle()
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.lg)
                .background(
                    LinearGradient(
                        colors: [Color.appBackground.opacity(0), Color.appBackground],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                    .offset(y: -50)
                )
            }
        }
    }

    private func chipButton(
        label: String,
        color: Color = Color.appPrimary,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
                .font(AppFont.caption())
                .fontWeight(isActive ? .semibold : .regular)
                .foregroundColor(isActive ? .white : color)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xxs + 2)
                .background(isActive ? color : color.opacity(0.12))
                .cornerRadius(AppRadius.full)
                .contentShape(Capsule())
        }
    }
}

#Preview {
    PrayerListView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}

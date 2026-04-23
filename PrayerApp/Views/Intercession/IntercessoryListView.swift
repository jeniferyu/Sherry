import CoreData
import SwiftUI

struct IntercessoryListView: View {
    @StateObject private var viewModel = IntercessoryViewModel()
    @State private var showingAddPrayer = false
    @State private var pendingDeletePrayerID: NSManagedObjectID?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                intercessionHeader

                GameSegmentedPicker(
                    selection: $viewModel.selectedTab,
                    options: IntercessoryTab.allCases,
                    label: \.rawValue
                )
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.xs)
                .padding(.bottom, AppSpacing.sm)

                groupFilterBar

                switch viewModel.selectedTab {
                case .current:
                    currentList
                case .history:
                    historyList
                }
            }
            .background(gameBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .deletePrayerConfirmation(pendingID: $pendingDeletePrayerID) { item in
            viewModel.deleteItem(item)
        }
        .onAppear { viewModel.fetchIntercessoryItems() }
        .onReceive(
            NotificationCenter.default.publisher(
                for: .NSManagedObjectContextDidSave,
                object: PersistenceController.shared.viewContext
            )
        ) { _ in
            viewModel.fetchIntercessoryItems()
        }
        .sheet(isPresented: $showingAddPrayer, onDismiss: { viewModel.fetchIntercessoryItems() }) {
            intercessoryAddSheet
        }
    }

    // MARK: - Header

    private var intercessionHeader: some View {
        HStack(alignment: .center, spacing: AppSpacing.sm) {
            Button {
                showingAddPrayer = true
            } label: {
                intercessionHeaderGradientIcon(systemName: AppIcons.add)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add intercession")

            Spacer()

            Text("Intercession")
                .font(AppFont.largeTitle())
                .foregroundColor(Color.appTextPrimary)

            Spacer()

            NavigationLink {
                IntercessorySearchView(viewModel: viewModel)
            } label: {
                intercessionHeaderGradientIcon(systemName: AppIcons.search)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Search intercessions")
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.md)
        .padding(.bottom, AppSpacing.xs)
    }

    private func intercessionHeaderGradientIcon(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 17, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.appPrimary, Color.appAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: Color.appPrimary.opacity(0.3), radius: 5, y: 2)
    }

    // MARK: - Filter Chips

    private var groupFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                GameFilterChip(
                    label: "All",
                    tint: Color.appPrimary,
                    isActive: viewModel.selectedGroup == nil
                ) {
                    viewModel.filterByGroup(nil)
                }
                ForEach(IntercessoryGroup.allCases, id: \.self) { group in
                    GameFilterChip(
                        label: group.displayName,
                        tint: group.accentColor,
                        isActive: viewModel.selectedGroup == group
                    ) {
                        viewModel.filterByGroup(group)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.xxs)
        }
    }

    // MARK: - Lists

    private var currentList: some View {
        Group {
            if viewModel.activeItems.isEmpty {
                EmptyStateView(
                    iconName: "person.2.fill",
                    title: "No Intercessory Prayers",
                    message: "Pray for others and keep them in your heart.",
                    actionTitle: "Add Intercession",
                    action: { showingAddPrayer = true }
                )
            } else {
                List {
                    ForEach(viewModel.activeItems) { item in
                        ZStack {
                            NavigationLink(destination: IntercessoryDetailView(
                                prayer: item,
                                onMarkAnswered: { viewModel.markAnswered(item) },
                                onArchive: { viewModel.archiveItem(item) },
                                onAddToToday: { viewModel.addToTodaySession(item) }
                            )) { EmptyView() }
                                .opacity(0)

                            IntercessoryPrayerRow(item: item)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: AppSpacing.lg, bottom: 6, trailing: AppSpacing.lg))
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                pendingDeletePrayerID = item.objectID
                            } label: {
                                Label("Delete", systemImage: AppIcons.delete)
                            }
                            .tint(.red)

                            if item.statusEnum != .archived {
                                Button {
                                    viewModel.archiveItem(item)
                                } label: {
                                    Label("Archive", systemImage: AppIcons.archive)
                                }
                                .tint(.gray)
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                viewModel.addToTodaySession(item)
                            } label: {
                                Label("Pray Today", systemImage: AppIcons.addToToday)
                            }
                            .tint(Color.appPrimary)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 100)
                }
            }
        }
    }

    private var historyList: some View {
        Group {
            if viewModel.answeredItems.isEmpty && viewModel.archivedItems.isEmpty {
                EmptyStateView(
                    iconName: AppIcons.answered,
                    title: "No History Yet",
                    message: "Answered and archived intercessions will appear here."
                )
            } else {
                List {
                    ForEach(viewModel.answeredItems) { item in
                        ZStack {
                            NavigationLink(destination: IntercessoryDetailView(prayer: item)) { EmptyView() }
                                .opacity(0)
                            IntercessoryPrayerRow(item: item)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: AppSpacing.lg, bottom: 6, trailing: AppSpacing.lg))
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                pendingDeletePrayerID = item.objectID
                            } label: {
                                Label("Delete", systemImage: AppIcons.delete)
                            }
                            .tint(.red)

                            Button {
                                viewModel.archiveItem(item)
                            } label: {
                                Label("Archive", systemImage: AppIcons.archive)
                            }
                            .tint(.gray)
                        }
                    }

                    ForEach(viewModel.archivedItems) { item in
                        ZStack {
                            NavigationLink(destination: IntercessoryDetailView(prayer: item)) { EmptyView() }
                                .opacity(0)
                            IntercessoryPrayerRow(item: item)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: AppSpacing.lg, bottom: 6, trailing: AppSpacing.lg))
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                pendingDeletePrayerID = item.objectID
                            } label: {
                                Label("Delete", systemImage: AppIcons.delete)
                            }
                            .tint(.red)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 100)
                }
            }
        }
    }

    // MARK: - Add Sheet

    private var intercessoryAddSheet: some View {
        let vm = PrayerCaptureViewModel()
        vm.isIntercessory = true
        return PrayerCaptureFormView(
            viewModel: vm,
            onSaveForLater: { showingAddPrayer = false }
        )
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
}

// MARK: - List row (shared with search)

struct IntercessoryPrayerRow: View {
    @ObservedObject var item: PrayerItem

    var body: some View {
        let baseColor = item.intercessoryGroupEnum?.accentColor ?? Color.appPrimary
        HStack(spacing: AppSpacing.md) {
            groupAvatar(for: item.intercessoryGroupEnum)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title ?? "")
                    .font(AppFont.headline())
                    .foregroundColor(.white)
                    .lineLimit(1)

                if let content = item.content, !content.isEmpty {
                    Text(content)
                        .font(AppFont.caption())
                        .foregroundColor(Color.white.opacity(0.85))
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    statusChip
                    GoldCountPill(
                        icon: AppIcons.star,
                        text: "\(item.prayedCount)"
                    )
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color.white.opacity(0.7))
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + 2)
        .gameCardStyle(color: baseColor)
    }

    private func groupAvatar(for group: IntercessoryGroup?) -> some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
            Image(systemName: group?.iconName ?? "person.2.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(group?.accentColor ?? Color.appPrimary)
        }
        .frame(width: 48, height: 48)
    }

    /// Same pattern as `PrayerCardView.statusChip` (Unprayed / Prayed / Answered / Archived).
    private var statusChip: some View {
        HStack(spacing: 3) {
            Image(systemName: item.statusEnum.iconName)
                .font(.system(size: 10, weight: .bold))
            Text(item.statusEnum.displayName)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule().fill(Color.white.opacity(0.22))
        )
    }
}

// MARK: - Search

struct IntercessorySearchView: View {
    @ObservedObject var viewModel: IntercessoryViewModel
    @State private var pendingDeletePrayerID: NSManagedObjectID?

    private var searchBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.98, blue: 0.96),
                Color.appBackground,
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var hasAnyResults: Bool {
        !viewModel.activeItems.isEmpty
            || !viewModel.answeredItems.isEmpty
            || !viewModel.archivedItems.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            intercessorySearchField
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.xs)

            filterScroll

            if hasAnyResults {
                List {
                    ForEach(viewModel.activeItems) { item in
                        ZStack {
                            NavigationLink(
                                destination: IntercessoryDetailView(
                                    prayer: item,
                                    onMarkAnswered: { viewModel.markAnswered(item) },
                                    onArchive: { viewModel.archiveItem(item) },
                                    onAddToToday: { viewModel.addToTodaySession(item) }
                                )
                            ) { EmptyView() }
                            .opacity(0)

                            IntercessoryPrayerRow(item: item)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: AppSpacing.lg, bottom: 6, trailing: AppSpacing.lg))
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                pendingDeletePrayerID = item.objectID
                            } label: {
                                Label("Delete", systemImage: AppIcons.delete)
                            }
                            .tint(.red)

                            if item.statusEnum != .archived {
                                Button {
                                    viewModel.archiveItem(item)
                                } label: {
                                    Label("Archive", systemImage: AppIcons.archive)
                                }
                                .tint(.gray)
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                viewModel.addToTodaySession(item)
                            } label: {
                                Label("Pray Today", systemImage: AppIcons.addToToday)
                            }
                            .tint(Color.appPrimary)
                        }
                    }

                    ForEach(viewModel.answeredItems) { item in
                        ZStack {
                            NavigationLink(destination: IntercessoryDetailView(prayer: item)) { EmptyView() }
                                .opacity(0)
                            IntercessoryPrayerRow(item: item)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: AppSpacing.lg, bottom: 6, trailing: AppSpacing.lg))
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                pendingDeletePrayerID = item.objectID
                            } label: {
                                Label("Delete", systemImage: AppIcons.delete)
                            }
                            .tint(.red)

                            Button {
                                viewModel.archiveItem(item)
                            } label: {
                                Label("Archive", systemImage: AppIcons.archive)
                            }
                            .tint(.gray)
                        }
                    }

                    ForEach(viewModel.archivedItems) { item in
                        ZStack {
                            NavigationLink(destination: IntercessoryDetailView(prayer: item)) { EmptyView() }
                                .opacity(0)
                            IntercessoryPrayerRow(item: item)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: AppSpacing.lg, bottom: 6, trailing: AppSpacing.lg))
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                pendingDeletePrayerID = item.objectID
                            } label: {
                                Label("Delete", systemImage: AppIcons.delete)
                            }
                            .tint(.red)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 100)
                }
            } else {
                EmptyStateView(
                    iconName: AppIcons.search,
                    title: "No Results",
                    message: "Try adjusting your search or filters."
                )
            }
        }
        .background(searchBackground.ignoresSafeArea())
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarPlainBackButton()
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(searchBackground, for: .navigationBar)
        .tint(Color.appPrimary)
        .deletePrayerConfirmation(pendingID: $pendingDeletePrayerID) { item in
            viewModel.deleteItem(item)
        }
        .onChange(of: viewModel.searchText) { _ in
            viewModel.fetchIntercessorySearchItems()
        }
        .onAppear {
            viewModel.intercessorySearchContextActive = true
            viewModel.fetchIntercessorySearchItems()
        }
        .onDisappear {
            viewModel.intercessorySearchContextActive = false
            viewModel.searchText = ""
            viewModel.searchStatusFilter = nil
            viewModel.searchGroupFilter = nil
            viewModel.fetchIntercessoryItems()
        }
    }

    // MARK: - Search field (matches `PrayerSearchView`)

    private var intercessorySearchField: some View {
        HStack(spacing: AppSpacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.12))
                Image(systemName: AppIcons.search)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.appPrimary)
            }
            .frame(width: 36, height: 36)

            TextField("Search intercessions…", text: $viewModel.searchText)
                .font(AppFont.body())
                .textInputAutocapitalization(.sentences)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                    viewModel.fetchIntercessorySearchItems()
                } label: {
                    Image(systemName: AppIcons.close)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color.appTextSecondary)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color.appSurfaceSecond))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
    }

    // MARK: - Filter chips (status matches prayer search; types = intercession groups)

    private var filterScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                GameFilterChip(
                    label: "All Status",
                    tint: Color.appPrimary,
                    isActive: viewModel.searchStatusFilter == nil
                ) {
                    viewModel.searchStatusFilter = nil
                    viewModel.fetchIntercessorySearchItems()
                }

                ForEach(PrayerStatus.allCases, id: \.self) { status in
                    GameFilterChip(
                        label: status.displayName,
                        tint: status.searchFilterChipTint,
                        isActive: viewModel.searchStatusFilter == status,
                        systemIcon: status.iconName,
                        action: {
                            viewModel.searchStatusFilter = (viewModel.searchStatusFilter == status) ? nil : status
                            viewModel.fetchIntercessorySearchItems()
                        }
                    )
                }

                filterSectionDivider

                ForEach(IntercessoryGroup.allCases, id: \.self) { group in
                    GameFilterChip(
                        label: group.displayName,
                        tint: group.accentColor,
                        isActive: viewModel.searchGroupFilter == group,
                        systemIcon: group.iconName,
                        action: {
                            viewModel.searchGroupFilter = (viewModel.searchGroupFilter == group) ? nil : group
                            viewModel.fetchIntercessorySearchItems()
                        }
                    )
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.sm)
        }
    }

    private var filterSectionDivider: some View {
        Capsule()
            .fill(Color.appTextTertiary.opacity(0.35))
            .frame(width: 2, height: 22)
    }
}

#Preview {
    IntercessoryListView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}

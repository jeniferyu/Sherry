import SwiftUI

struct IntercessoryListView: View {
    @StateObject private var viewModel = IntercessoryViewModel()
    @State private var showingAddPrayer = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Tab", selection: $viewModel.selectedTab) {
                    ForEach(IntercessoryTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.sm)

                // Group filter chips
                groupFilterBar

                // Content
                switch viewModel.selectedTab {
                case .current:
                    currentList
                case .history:
                    historyList
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Intercession")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddPrayer = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(Color.appPrimary)
                    }
                }
            }
        }
        .onAppear { viewModel.fetchIntercessoryItems() }
        .sheet(isPresented: $showingAddPrayer, onDismiss: { viewModel.fetchIntercessoryItems() }) {
            intercessoryAddSheet
        }
    }

    // MARK: - Subviews

    private var groupFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                groupChip(label: "All", group: nil)
                ForEach(IntercessoryGroup.allCases, id: \.self) { group in
                    groupChip(label: group.displayName, group: group)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.xs)
        }
    }

    private var currentList: some View {
        Group {
            if viewModel.activeItems.isEmpty {
                EmptyStateView(
                    iconName: "person.2",
                    title: "No Intercessory Prayers",
                    message: "Add prayers for others by tapping the + button.",
                    actionTitle: "Add Intercession",
                    action: { showingAddPrayer = true }
                )
            } else {
                List {
                    ForEach(viewModel.activeItems) { item in
                        NavigationLink(destination: IntercessoryDetailView(
                            prayer: item,
                            onMarkAnswered: { viewModel.markAnswered(item) },
                            onArchive: { viewModel.archiveItem(item) },
                            onAddToToday: { viewModel.addToTodaySession(item) }
                        )) {
                            intercessoryRow(item)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                viewModel.markAnswered(item)
                            } label: {
                                Label("Answered", systemImage: AppIcons.markAnswered)
                            }
                            .tint(.yellow)

                            Button {
                                viewModel.archiveItem(item)
                            } label: {
                                Label("Archive", systemImage: AppIcons.archive)
                            }
                            .tint(.gray)
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
                .background(Color.appBackground)
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
                    if !viewModel.answeredItems.isEmpty {
                        Section {
                            ForEach(viewModel.answeredItems) { item in
                                NavigationLink(destination: IntercessoryDetailView(prayer: item)) {
                                    intercessoryRow(item)
                                }
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .listRowSeparator(.hidden)
                            }
                        } header: {
                            sectionHeader("Answered \u{2728}", color: .appAnswered)
                        }
                    }

                    if !viewModel.archivedItems.isEmpty {
                        Section {
                            ForEach(viewModel.archivedItems) { item in
                                NavigationLink(destination: IntercessoryDetailView(prayer: item)) {
                                    intercessoryRow(item)
                                }
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .listRowSeparator(.hidden)
                            }
                        } header: {
                            sectionHeader("Archived", color: .appArchived)
                        }
                    }
                }
                .listStyle(.plain)
                .background(Color.appBackground)
            }
        }
    }

    private func intercessoryRow(_ item: PrayerItem) -> some View {
        HStack(spacing: AppSpacing.md) {
            // Group icon circle
            if let group = item.intercessoryGroupEnum {
                Image(systemName: group.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(Color.appPrimary)
                    .frame(width: 40, height: 40)
                    .background(Color.appPrimary.opacity(0.12))
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(item.title ?? "")
                    .font(AppFont.headline())
                    .foregroundColor(Color.appTextPrimary)
                    .lineLimit(1)
                if let content = item.content, !content.isEmpty {
                    Text(content)
                        .font(AppFont.caption())
                        .foregroundColor(Color.appTextSecondary)
                        .lineLimit(1)
                }
                HStack(spacing: AppSpacing.xs) {
                    if let group = item.intercessoryGroupEnum {
                        Text(group.displayName)
                            .font(AppFont.caption2())
                            .foregroundColor(Color.appTextTertiary)
                    }
                    Text("\u{2022}")
                        .foregroundColor(Color.appTextTertiary)
                        .font(AppFont.caption2())
                    Text("\(item.prayedCount)x prayed")
                        .font(AppFont.caption2())
                        .foregroundColor(Color.appTextTertiary)
                }
            }

            Spacer()

            StatusIndicator(status: item.statusEnum, showLabel: false)
        }
        .padding(AppSpacing.md)
        .cardStyle()
    }

    private func groupChip(label: String, group: IntercessoryGroup?) -> some View {
        Button {
            viewModel.filterByGroup(group)
        } label: {
            Text(label)
                .font(AppFont.caption())
                .foregroundColor(viewModel.selectedGroup == group ? .white : Color.appPrimary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xxs + 2)
                .background(viewModel.selectedGroup == group ? Color.appPrimary : Color.appPrimary.opacity(0.12))
                .cornerRadius(AppRadius.full)
                .contentShape(Capsule())
        }
    }

    private func sectionHeader(_ title: String, color: Color) -> some View {
        Text(title)
            .font(AppFont.caption())
            .fontWeight(.semibold)
            .foregroundColor(color)
            .textCase(nil)
            .padding(.vertical, AppSpacing.xxs)
    }

    private var intercessoryAddSheet: some View {
        let vm = PrayerCaptureViewModel()
        vm.isIntercessory = true
        return PrayerCaptureFormView(
            viewModel: vm,
            onSaveForLater: { showingAddPrayer = false }
        )
    }
}

#Preview {
    IntercessoryListView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}

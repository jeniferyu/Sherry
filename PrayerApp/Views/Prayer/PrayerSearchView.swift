import SwiftUI

struct PrayerSearchView: View {
    @StateObject private var viewModel = PrayerListViewModel()
    @State private var showingFilters = false

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: AppIcons.search)
                    .foregroundColor(Color.appTextTertiary)
                TextField("Search prayers...", text: $viewModel.searchText)
                    .font(AppFont.body())
                    .onChange(of: viewModel.searchText) { _ in viewModel.fetchPrayers() }

                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                        viewModel.fetchPrayers()
                    } label: {
                        Image(systemName: AppIcons.close)
                            .foregroundColor(Color.appTextTertiary)
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(Color.appSurface)
            .cornerRadius(AppRadius.lg)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.sm)

            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    filterChip(
                        label: "All Status",
                        isActive: viewModel.statusFilter == nil,
                        action: { viewModel.filterByStatus(nil) }
                    )
                    ForEach(PrayerStatus.allCases, id: \.self) { status in
                        filterChip(
                            label: status.displayName,
                            icon: status.iconName,
                            color: status.color,
                            isActive: viewModel.statusFilter == status,
                            action: { viewModel.filterByStatus(status) }
                        )
                    }
                    Divider().frame(height: 20)
                    ForEach(PrayerCategory.allCases, id: \.self) { category in
                        filterChip(
                            label: category.displayName,
                            icon: category.iconName,
                            color: category.fallbackColor,
                            isActive: viewModel.categoryFilter == category,
                            action: { viewModel.filterByCategory(category) }
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }
            .padding(.bottom, AppSpacing.xs)

            // Results
            if viewModel.prayers.isEmpty {
                EmptyStateView(
                    iconName: AppIcons.search,
                    title: "No Results",
                    message: "Try adjusting your search or filters."
                )
            } else {
                List {
                    ForEach(viewModel.prayers) { prayer in
                        NavigationLink(destination: PrayerDetailView(
                            prayer: prayer,
                            onStatusChange: { viewModel.updateStatus(prayer, status: $0) }
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
                .listStyle(.plain)
                .background(Color.appBackground)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Search Prayers")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.fetchPrayers() }
    }

    private func filterChip(
        label: String,
        icon: String? = nil,
        color: Color = Color.appPrimary,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xxs) {
                if let icon {
                    Image(systemName: icon).font(.system(size: 11))
                }
                Text(label).font(AppFont.caption())
            }
            .foregroundColor(isActive ? .white : color)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(isActive ? color : color.opacity(0.12))
            .cornerRadius(AppRadius.full)
            .contentShape(Capsule())
        }
    }
}

#Preview {
    NavigationStack {
        PrayerSearchView()
    }
}

import CoreData
import SwiftUI

struct PrayerSearchView: View {
    @StateObject private var viewModel = PrayerListViewModel()
    @State private var pendingDeletePrayerID: NSManagedObjectID?

    var body: some View {
        VStack(spacing: 0) {
            gameSearchField
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.xs)

            filterScroll

            if viewModel.prayers.isEmpty {
                EmptyStateView(
                    iconName: AppIcons.search,
                    title: "No Results",
                    message: "Try adjusting your search or filters."
                )
            } else {
                resultsList
            }
        }
        .background(gameBackground.ignoresSafeArea())
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarPlainBackButton()
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(gameBackground, for: .navigationBar)
        .tint(Color.appPrimary)
        .deletePrayerConfirmation(pendingID: $pendingDeletePrayerID) { prayer in
            viewModel.deletePrayer(prayer)
        }
        .onAppear {
            viewModel.isSearchMode = true
            viewModel.searchAllPrayers()
        }
        .onDisappear {
            viewModel.isSearchMode = false
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

    // MARK: - Search Field

    private var gameSearchField: some View {
        HStack(spacing: AppSpacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.12))
                Image(systemName: AppIcons.search)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.appPrimary)
            }
            .frame(width: 36, height: 36)

            TextField("Search prayers…", text: $viewModel.searchText)
                .font(AppFont.body())
                .textInputAutocapitalization(.sentences)
                .onChange(of: viewModel.searchText) { _ in viewModel.searchAllPrayers() }

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                    viewModel.searchAllPrayers()
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

    // MARK: - Filters

    private var filterScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                GameFilterChip(
                    label: "All Status",
                    tint: Color.appPrimary,
                    isActive: viewModel.statusFilter == nil,
                    action: {
                        viewModel.statusFilter = nil
                        viewModel.searchAllPrayers()
                    }
                )

                ForEach(PrayerStatus.allCases, id: \.self) { status in
                    GameFilterChip(
                        label: status.displayName,
                        tint: status.searchFilterChipTint,
                        isActive: viewModel.statusFilter == status,
                        systemIcon: status.iconName,
                        action: {
                            viewModel.statusFilter = (viewModel.statusFilter == status) ? nil : status
                            viewModel.searchAllPrayers()
                        }
                    )
                }

                filterSectionDivider

                ForEach(PrayerCategory.allCases, id: \.self) { category in
                    GameFilterChip(
                        label: category.displayName,
                        tint: category.fallbackColor,
                        isActive: viewModel.categoryFilter == category,
                        systemIcon: category.isAssetIcon ? nil : category.iconName,
                        assetIconName: category.isAssetIcon ? category.iconName : nil,
                        action: {
                            viewModel.categoryFilter = (viewModel.categoryFilter == category) ? nil : category
                            viewModel.searchAllPrayers()
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

    // MARK: - Results

    private var resultsList: some View {
        List {
            ForEach(viewModel.prayers) { prayer in
                ZStack {
                    NavigationLink(destination: PrayerDetailView(
                        prayer: prayer,
                        onStatusChange: { viewModel.updateStatus(prayer, status: $0) },
                        onAddToToday: { viewModel.addPersonalPrayerToToday(prayer) }
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
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }
}

#Preview {
    NavigationStack {
        PrayerSearchView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}

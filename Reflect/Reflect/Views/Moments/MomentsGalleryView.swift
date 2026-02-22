import SwiftUI
import SwiftData

struct MomentsGalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = MomentsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.moments.isEmpty {
                    emptyState
                } else {
                    momentsContent
                }
            }
            .navigationTitle(Strings.momentsTitle)
            .onAppear { viewModel.setup(context: modelContext) }
            .sheet(isPresented: $viewModel.showSaveMomentSheet) {
                SaveMomentView(
                    sourceType: viewModel.savingSourceType,
                    sourceId: viewModel.savingSourceId,
                    prefilledQuote: viewModel.quote
                )
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            icon: "sparkles.rectangle.stack",
            title: Strings.momentsNoMoments,
            message: Strings.momentsNoMomentsBody
        )
    }

    // MARK: - Content

    private var momentsContent: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColor.secondaryLabel)
                TextField("Search moments...", text: $viewModel.searchText)
                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColor.secondaryLabel)
                    }
                }
            }
            .padding(Spacing.md)
            .background(AppColor.secondaryBackground)
            .cornerRadius(CornerRadius.sm)
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.sm)

            // Filter chips
            if !viewModel.allTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        // "All" chip
                        filterChip(label: "All", isSelected: viewModel.filterTag == nil) {
                            viewModel.clearFilters()
                        }

                        ForEach(viewModel.allTags.prefix(10), id: \.self) { tag in
                            filterChip(label: tag, isSelected: viewModel.filterTag == tag) {
                                if viewModel.filterTag == tag {
                                    viewModel.filterTag = nil
                                } else {
                                    viewModel.filterTag = tag
                                }
                                viewModel.applyFilters()
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                }
            }

            // Moments list
            if viewModel.filteredMoments.isEmpty {
                Spacer()
                Text(Strings.noResults)
                    .font(AppFont.body)
                    .foregroundColor(AppColor.secondaryLabel)
                Spacer()
            } else {
                List {
                    ForEach(viewModel.filteredMoments, id: \.id) { moment in
                        MomentCardView(moment: moment)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            _ = viewModel.deleteMoment(viewModel.filteredMoments[index])
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    // MARK: - Filter Chip

    private func filterChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(AppFont.caption)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(isSelected ? AppColor.primary.opacity(0.2) : AppColor.tertiaryBackground)
                .foregroundColor(isSelected ? AppColor.primary : AppColor.secondaryLabel)
                .cornerRadius(CornerRadius.xl)
        }
        .buttonStyle(.plain)
    }
}

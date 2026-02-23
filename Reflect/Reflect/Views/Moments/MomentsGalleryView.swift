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
            .toolbar(.hidden, for: .navigationBar)
            .warmBackground()
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
            // Search bar — warm styling
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColor.secondaryLabel)
                    .font(.system(size: 14))
                TextField("Search moments...", text: $viewModel.searchText)
                    .font(AppFont.body)
                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColor.secondaryLabel)
                            .font(.system(size: 14))
                    }
                }
            }
            .padding(Spacing.md)
            .background(AppColor.cardBackground)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(AppColor.separator.opacity(0.3), lineWidth: 0.5)
            )
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.sm)

            // Filter chips
            if !viewModel.allTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
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
                    .padding(.vertical, Spacing.md)
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
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        ForEach(viewModel.filteredMoments, id: \.id) { moment in
                            MomentCardView(moment: moment)
                                .cardStyle()
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, 80) // Tab bar spacing
                }
            }
        }
    }

    // MARK: - Filter Chip

    private func filterChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(AppFont.caption)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(isSelected ? AppColor.amber.opacity(0.15) : AppColor.cardBackground)
                .foregroundColor(isSelected ? AppColor.amber : AppColor.secondaryLabel)
                .cornerRadius(CornerRadius.pill)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.pill)
                        .stroke(isSelected ? AppColor.amber.opacity(0.3) : AppColor.separator.opacity(0.3), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }
}

import SwiftUI

/// A flow-layout tag picker that allows selecting multiple tags from a list.
struct TagPickerView<Tag: Identifiable & Hashable>: View where Tag: RawRepresentable, Tag.RawValue == String {
    let title: String
    let allTags: [Tag]
    @Binding var selectedTags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(AppFont.callout)
                .foregroundColor(AppColor.label)

            FlowLayout(spacing: Spacing.sm) {
                ForEach(allTags) { tag in
                    TagChip(
                        label: tag.rawValue,
                        isSelected: selectedTags.contains(tag.rawValue),
                        action: { toggleTag(tag.rawValue) }
                    )
                }
            }
        }
    }

    private func toggleTag(_ tag: String) {
        if let index = selectedTags.firstIndex(of: tag) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }
}

// MARK: - Simple String Tag Picker

struct SimpleTagPickerView: View {
    let title: String
    let options: [String]
    @Binding var selectedTags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(AppFont.callout)
                .foregroundColor(AppColor.label)

            FlowLayout(spacing: Spacing.sm) {
                ForEach(options, id: \.self) { tag in
                    TagChip(
                        label: tag,
                        isSelected: selectedTags.contains(tag),
                        action: { toggleTag(tag) }
                    )
                }
            }
        }
    }

    private func toggleTag(_ tag: String) {
        if let index = selectedTags.firstIndex(of: tag) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }
}

// MARK: - Tag Chip

struct TagChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AppFont.caption)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(isSelected ? AppColor.primary.opacity(0.2) : AppColor.tertiaryBackground)
                .foregroundColor(isSelected ? AppColor.primary : AppColor.secondaryLabel)
                .cornerRadius(CornerRadius.xl)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.xl)
                        .stroke(isSelected ? AppColor.primary.opacity(0.5) : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout

/// A simple flow layout that wraps items to the next line when they exceed the available width.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layoutSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layoutSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func layoutSubviews(proposal: ProposedViewSize, subviews: Subviews) -> LayoutResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        let totalHeight = currentY + lineHeight
        return LayoutResult(
            size: CGSize(width: maxWidth, height: totalHeight),
            positions: positions
        )
    }

    struct LayoutResult {
        let size: CGSize
        let positions: [CGPoint]
    }
}

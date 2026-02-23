import SwiftUI

/// Displays an AI lens response in a warm expandable card.
struct LensResponseCard: View {
    let response: LensResponse
    @State private var isExpanded = false

    private var lensColor: Color {
        switch response.lensType {
        case .grounding: return AppColor.groundingLens
        case .meaning: return AppColor.meaningLens
        case .integration: return AppColor.integrationLens
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Button(action: { withAnimation(.easeInOut(duration: 0.3)) { isExpanded.toggle() } }) {
                HStack {
                    // Warm icon dot
                    Circle()
                        .fill(lensColor.opacity(0.2))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: response.lensType.iconName)
                                .font(.system(size: 12))
                                .foregroundColor(lensColor)
                        )

                    Text(response.lensType.rawValue)
                        .font(AppFont.headline)
                        .foregroundColor(AppColor.label)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .foregroundColor(AppColor.secondaryLabel)
                        .font(.caption)
                        .rotationEffect(.degrees(isExpanded ? -180 : 0))
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                // Warm separator
                Rectangle()
                    .fill(lensColor.opacity(0.15))
                    .frame(height: 0.5)

                Text(response.content)
                    .font(AppFont.body)
                    .foregroundColor(AppColor.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(lensColor.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(lensColor.opacity(0.15), lineWidth: 0.5)
        )
    }
}

/// A section that displays all lens responses for a given entry.
struct LensResponsesSection: View {
    let responses: [LensResponse]

    var body: some View {
        if !responses.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("AI Reflections")
                    .font(AppFont.headline)
                    .foregroundColor(AppColor.label)

                ForEach(responses, id: \.id) { response in
                    LensResponseCard(response: response)
                }
            }
        }
    }
}

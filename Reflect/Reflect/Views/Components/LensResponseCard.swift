import SwiftUI

/// Displays an AI lens response in an expandable card.
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
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: response.lensType.iconName)
                        .foregroundColor(lensColor)
                    Text(response.lensType.rawValue)
                        .font(AppFont.headline)
                        .foregroundColor(AppColor.label)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(AppColor.secondaryLabel)
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(response.content)
                    .font(AppFont.body)
                    .foregroundColor(AppColor.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            }
        }
        .padding(Spacing.md)
        .background(lensColor.opacity(0.05))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(lensColor.opacity(0.2), lineWidth: 1)
        )
    }
}

/// A section that displays all lens responses for a given entry.
struct LensResponsesSection: View {
    let responses: [LensResponse]

    var body: some View {
        if !responses.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("AI Reflections")
                    .font(AppFont.headline)
                    .foregroundColor(AppColor.label)
                    .padding(.bottom, Spacing.xs)

                ForEach(responses, id: \.id) { response in
                    LensResponseCard(response: response)
                }
            }
        }
    }
}

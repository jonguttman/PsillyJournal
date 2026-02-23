import SwiftUI

struct MomentCardView: View {
    let moment: Moment

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Quote — serif italic for that journal feel
            Text("\"\(moment.quote)\"")
                .font(.system(.body, design: .serif))
                .italic()
                .foregroundColor(AppColor.label)
                .fixedSize(horizontal: false, vertical: true)

            // "What this asks of me"
            if !moment.askOfMe.isEmpty {
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Rectangle()
                        .fill(AppColor.amber.opacity(0.4))
                        .frame(width: 2)
                        .cornerRadius(1)

                    Text(moment.askOfMe)
                        .font(AppFont.callout)
                        .foregroundColor(AppColor.secondaryLabel)
                }
                .padding(.leading, Spacing.xs)
            }

            // Tags row
            HStack(spacing: Spacing.sm) {
                // Themes
                ForEach(moment.themes.prefix(2), id: \.self) { tag in
                    tagPill(tag, color: AppColor.sage)
                }

                // Emotions
                ForEach(moment.emotions.prefix(2), id: \.self) { tag in
                    tagPill(tag, color: AppColor.warmIndigo)
                }

                Spacer()

                // Intensity
                if moment.intensity > 0 {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                        Text("\(moment.intensity)")
                            .font(AppFont.captionSecondary)
                    }
                    .foregroundColor(AppColor.energy)
                }
            }

            // Footer
            HStack {
                Text(moment.formattedDate)
                    .font(AppFont.captionSecondary)
                    .foregroundColor(AppColor.secondaryLabel)
                Spacer()
                Image(systemName: moment.sourceType == .checkIn ? "sun.max" : "brain.head.profile")
                    .font(.caption2)
                    .foregroundColor(AppColor.secondaryLabel.opacity(0.6))
            }
        }
        .padding(.vertical, Spacing.sm)
    }

    private func tagPill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(AppFont.captionSecondary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(CornerRadius.pill)
    }
}

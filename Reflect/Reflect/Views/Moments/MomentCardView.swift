import SwiftUI

struct MomentCardView: View {
    let moment: Moment

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Quote
            Text("\"\(moment.quote)\"")
                .font(AppFont.body)
                .italic()
                .foregroundColor(AppColor.label)
                .fixedSize(horizontal: false, vertical: true)

            // "What this asks of me"
            if !moment.askOfMe.isEmpty {
                HStack(alignment: .top, spacing: Spacing.xs) {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.caption)
                        .foregroundColor(AppColor.primary)
                    Text(moment.askOfMe)
                        .font(AppFont.callout)
                        .foregroundColor(AppColor.secondaryLabel)
                }
            }

            // Tags row
            HStack(spacing: Spacing.sm) {
                // Themes
                ForEach(moment.themes.prefix(2), id: \.self) { tag in
                    tagPill(tag, color: AppColor.primary)
                }

                // Emotions
                ForEach(moment.emotions.prefix(2), id: \.self) { tag in
                    tagPill(tag, color: AppColor.mood)
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
                    .foregroundColor(AppColor.secondaryLabel)
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    private func tagPill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(AppFont.captionSecondary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(CornerRadius.xl)
    }
}

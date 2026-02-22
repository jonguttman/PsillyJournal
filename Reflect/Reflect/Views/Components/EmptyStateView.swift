import SwiftUI

/// A reusable empty state view with icon, title, message, and optional action button.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(AppColor.secondaryLabel.opacity(0.5))

            Text(title)
                .font(AppFont.title)
                .foregroundColor(AppColor.label)
                .multilineTextAlignment(.center)

            Text(message)
                .font(AppFont.body)
                .foregroundColor(AppColor.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)

            if let actionLabel, let action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(AppFont.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, Spacing.md)
                        .background(AppColor.primary)
                        .cornerRadius(CornerRadius.md)
                }
                .padding(.top, Spacing.sm)
            }
        }
        .padding(Spacing.xxl)
    }
}

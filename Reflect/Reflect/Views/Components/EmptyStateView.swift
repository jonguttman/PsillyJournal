import SwiftUI

/// A reusable empty state with warm halo, serif title, and optional action.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Spacing.xl) {
            // Icon with warm glow halo
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppColor.amber.opacity(0.12), AppColor.amber.opacity(0.0)],
                            center: .center,
                            startRadius: 10,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(AppColor.amber.opacity(0.5))
            }

            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(AppFont.title)
                    .foregroundColor(AppColor.label)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(AppFont.body)
                    .foregroundColor(AppColor.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xxl)
            }

            if let actionLabel, let action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(AppFont.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, Spacing.md)
                        .background(AppGradient.warmCTA)
                        .cornerRadius(CornerRadius.lg)
                        .shadow(color: AppColor.amber.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                .padding(.top, Spacing.sm)
            }
        }
        .padding(Spacing.xxl)
        .fadeRise(delay: 0.1)
    }
}

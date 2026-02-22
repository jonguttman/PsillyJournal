import SwiftUI

/// Presented when self-harm intent is detected in user input.
/// Shows emergency resources and crisis hotlines.
struct CrisisResourcesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 48))
                            .foregroundColor(AppColor.danger)

                        Text(Strings.crisisTitle)
                            .font(AppFont.largeTitle)
                            .foregroundColor(AppColor.label)
                            .multilineTextAlignment(.center)

                        Text(Strings.crisisBody)
                            .font(AppFont.body)
                            .foregroundColor(AppColor.secondaryLabel)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Spacing.xl)

                    // Emergency notice
                    HStack(spacing: Spacing.md) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title2)
                            .foregroundColor(AppColor.danger)
                        Text(Strings.crisisEmergency)
                            .font(AppFont.headline)
                            .foregroundColor(AppColor.label)
                    }
                    .padding(Spacing.lg)
                    .frame(maxWidth: .infinity)
                    .background(AppColor.crisisBackground)
                    .cornerRadius(CornerRadius.md)

                    // Resources
                    VStack(spacing: Spacing.md) {
                        // 988 Suicide & Crisis Lifeline
                        crisisResourceCard(
                            title: Strings.crisisHotlineUS,
                            detail: "Call or text \(Strings.crisisHotlineUSNumber)",
                            icon: "phone.fill",
                            action: { callNumber(Strings.crisisHotlineUSNumber) }
                        )

                        // Crisis Text Line
                        crisisResourceCard(
                            title: Strings.crisisCrisisTextLine,
                            detail: Strings.crisisCrisisTextLineInfo,
                            icon: "message.fill",
                            action: { sendSMS("741741", body: "HOME") }
                        )

                        // IMAlive
                        crisisResourceCard(
                            title: Strings.crisisIMAlive,
                            detail: Strings.crisisIMAliveInfo,
                            icon: "globe",
                            action: { openURL(URL(string: "https://www.imalive.org")!) }
                        )
                    }

                    // Dismiss button
                    Button(action: { dismiss() }) {
                        Text(Strings.crisisDismiss)
                            .font(AppFont.callout)
                            .foregroundColor(AppColor.secondaryLabel)
                            .padding(.vertical, Spacing.md)
                    }
                    .padding(.top, Spacing.lg)
                }
                .padding(Spacing.lg)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(AppColor.secondaryLabel)
                    }
                }
            }
        }
    }

    // MARK: - Resource Card

    private func crisisResourceCard(
        title: String,
        detail: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(AppColor.danger)
                    .cornerRadius(CornerRadius.sm)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(title)
                        .font(AppFont.headline)
                        .foregroundColor(AppColor.label)
                    Text(detail)
                        .font(AppFont.callout)
                        .foregroundColor(AppColor.secondaryLabel)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(AppColor.secondaryLabel)
            }
            .padding(Spacing.md)
            .background(AppColor.secondaryBackground)
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func callNumber(_ number: String) {
        if let url = URL(string: "tel://\(number)") {
            openURL(url)
        }
    }

    private func sendSMS(_ number: String, body: String) {
        if let url = URL(string: "sms:\(number)&body=\(body)") {
            openURL(url)
        }
    }
}

import SwiftUI

struct PrivacySettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section(header: Text(Strings.settingsAvoidTopics)) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(Strings.settingsAvoidTopicsHint)
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.secondaryLabel)

                    TextField(
                        "e.g. work, family, health",
                        text: Binding(
                            get: { viewModel.avoidTopicsText },
                            set: { viewModel.avoidTopicsText = $0 }
                        )
                    )
                    .textFieldStyle(.roundedBorder)
                }
            }

            Section(header: Text("Current Topics")) {
                if viewModel.preferences?.avoidTopics.isEmpty ?? true {
                    Text("No topics set. AI reflections will cover all subjects.")
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.secondaryLabel)
                } else {
                    FlowLayout(spacing: Spacing.sm) {
                        ForEach(viewModel.preferences?.avoidTopics ?? [], id: \.self) { topic in
                            HStack(spacing: Spacing.xs) {
                                Text(topic)
                                    .font(AppFont.caption)
                                Button(action: { removeTopic(topic) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption2)
                                }
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.xs)
                            .background(AppColor.danger.opacity(0.1))
                            .foregroundColor(AppColor.danger)
                            .cornerRadius(CornerRadius.xl)
                        }
                    }
                }
            }

            Section {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Label("How this works", systemImage: "info.circle")
                        .font(AppFont.headline)
                        .foregroundColor(AppColor.primary)

                    Text("Topics you add here will be excluded from AI-generated reflections. The AI will avoid referencing these subjects when responding to your journal entries.")
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.secondaryLabel)

                    Text("This only affects AI reflections — it does not filter your own journal entries.")
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.secondaryLabel)
                }
            }
        }
        .navigationTitle(Strings.settingsBoundaries)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func removeTopic(_ topic: String) {
        viewModel.preferences?.avoidTopics.removeAll { $0 == topic }
        viewModel.savePreferences()
    }
}

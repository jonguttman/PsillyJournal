import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var lockService: LockService
    @State private var viewModel = SettingsViewModel()
    @AppStorage("appLockEnabled") private var appLockEnabled = false

    var body: some View {
        NavigationStack {
            List {
                // Privacy & Security
                Section(header: sectionHeader(Strings.settingsPrivacy)) {
                    Toggle(isOn: $appLockEnabled) {
                        HStack(spacing: Spacing.md) {
                            settingIcon("lock.shield.fill", color: AppColor.amber)
                            VStack(alignment: .leading) {
                                Text(Strings.settingsAppLock)
                                    .font(AppFont.body)
                                    .foregroundColor(AppColor.label)
                                Text(Strings.settingsAppLockDesc)
                                    .font(AppFont.captionSecondary)
                                    .foregroundColor(AppColor.secondaryLabel)
                            }
                        }
                    }
                    .tint(AppColor.amber)

                    if !lockService.isAvailable {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(AppColor.warning)
                            Text("Biometric authentication is not available on this device. App lock may use device passcode.")
                                .font(AppFont.caption)
                                .foregroundColor(AppColor.secondaryLabel)
                        }
                    }
                }
                .listRowBackground(AppColor.cardBackground)

                // AI
                Section(header: sectionHeader(Strings.settingsAI)) {
                    NavigationLink(destination: AISettingsView(viewModel: viewModel)) {
                        HStack(spacing: Spacing.md) {
                            settingIcon("sparkles", color: AppColor.warmIndigo)
                            VStack(alignment: .leading) {
                                Text(Strings.aiEnabled)
                                    .font(AppFont.body)
                                    .foregroundColor(AppColor.label)
                                Text(viewModel.preferences?.aiEnabled == true ? "Enabled" : "Disabled")
                                    .font(AppFont.captionSecondary)
                                    .foregroundColor(AppColor.secondaryLabel)
                            }
                        }
                    }
                }
                .listRowBackground(AppColor.cardBackground)

                // Boundaries
                Section(header: sectionHeader(Strings.settingsBoundaries)) {
                    NavigationLink(destination: PrivacySettingsView(viewModel: viewModel)) {
                        HStack(spacing: Spacing.md) {
                            settingIcon("hand.raised.fill", color: AppColor.sage)
                            Text(Strings.settingsAvoidTopics)
                                .font(AppFont.body)
                                .foregroundColor(AppColor.label)
                        }
                    }
                }
                .listRowBackground(AppColor.cardBackground)

                // Data
                Section(header: sectionHeader(Strings.settingsData)) {
                    Button(action: { viewModel.exportJSON() }) {
                        HStack(spacing: Spacing.md) {
                            settingIcon("doc.text", color: AppColor.clay)
                            Text(Strings.settingsExportJSON)
                                .font(AppFont.body)
                                .foregroundColor(AppColor.label)
                        }
                    }

                    Button(action: { viewModel.exportText() }) {
                        HStack(spacing: Spacing.md) {
                            settingIcon("doc.plaintext", color: AppColor.clay)
                            Text(Strings.settingsExportText)
                                .font(AppFont.body)
                                .foregroundColor(AppColor.label)
                        }
                    }

                    if let date = viewModel.preferences?.lastExportDate {
                        Text("Last export: \(date.formatted(date: .abbreviated, time: .shortened))")
                            .font(AppFont.captionSecondary)
                            .foregroundColor(AppColor.secondaryLabel)
                    }
                }
                .listRowBackground(AppColor.cardBackground)

                // Delete All
                Section {
                    Button(role: .destructive, action: { viewModel.showDeleteConfirmation = true }) {
                        HStack(spacing: Spacing.md) {
                            settingIcon("trash", color: AppColor.danger)
                            Text(Strings.settingsDeleteAll)
                                .font(AppFont.body)
                                .foregroundColor(AppColor.danger)
                        }
                    }
                }
                .listRowBackground(AppColor.cardBackground)

                // About
                Section(header: sectionHeader(Strings.settingsAbout)) {
                    HStack {
                        Text(Strings.appName)
                            .font(AppFont.body)
                            .foregroundColor(AppColor.label)
                        Spacer()
                        Text(Strings.appTagline)
                            .font(.system(.caption, design: .serif))
                            .italic()
                            .foregroundColor(AppColor.secondaryLabel)
                    }
                    HStack {
                        Text(Strings.settingsVersion)
                            .font(AppFont.body)
                            .foregroundColor(AppColor.label)
                        Spacer()
                        Text("1.0.0")
                            .font(AppFont.caption)
                            .foregroundColor(AppColor.secondaryLabel)
                    }
                }
                .listRowBackground(AppColor.cardBackground)
            }
            .scrollContentBackground(.hidden)
            .warmBackground()
            .navigationTitle(Strings.settingsTitle)
            .onAppear { viewModel.setup(context: modelContext) }
            .alert(Strings.settingsDeleteAll, isPresented: $viewModel.showDeleteConfirmation) {
                Button(Strings.delete, role: .destructive) {
                    viewModel.deleteAllData()
                }
                Button(Strings.cancel, role: .cancel) {}
            } message: {
                Text(Strings.settingsDeleteAllConfirm)
            }
            .sheet(isPresented: $viewModel.showShareSheet) {
                if let url = viewModel.exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(AppFont.caption)
            .foregroundColor(AppColor.amber.opacity(0.8))
            .textCase(nil)
    }

    private func settingIcon(_ name: String, color: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: 14))
            .foregroundColor(color)
            .frame(width: 28, height: 28)
            .background(color.opacity(0.1))
            .cornerRadius(CornerRadius.sm)
    }
}

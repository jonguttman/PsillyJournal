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
                Section(header: Text(Strings.settingsPrivacy)) {
                    Toggle(isOn: $appLockEnabled) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(AppColor.primary)
                            VStack(alignment: .leading) {
                                Text(Strings.settingsAppLock)
                                Text(Strings.settingsAppLockDesc)
                                    .font(AppFont.captionSecondary)
                                    .foregroundColor(AppColor.secondaryLabel)
                            }
                        }
                    }

                    if !lockService.isAvailable {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(AppColor.warning)
                            Text("Biometric authentication is not available on this device. App lock may use device passcode.")
                                .font(AppFont.caption)
                                .foregroundColor(AppColor.secondaryLabel)
                        }
                    }
                }

                // AI
                Section(header: Text(Strings.settingsAI)) {
                    NavigationLink(destination: AISettingsView(viewModel: viewModel)) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(AppColor.meaningLens)
                            VStack(alignment: .leading) {
                                Text(Strings.aiEnabled)
                                Text(viewModel.preferences?.aiEnabled == true ? "Enabled" : "Disabled")
                                    .font(AppFont.captionSecondary)
                                    .foregroundColor(AppColor.secondaryLabel)
                            }
                        }
                    }
                }

                // Boundaries
                Section(header: Text(Strings.settingsBoundaries)) {
                    NavigationLink(destination: PrivacySettingsView(viewModel: viewModel)) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(AppColor.safe)
                            Text(Strings.settingsAvoidTopics)
                        }
                    }
                }

                // Data
                Section(header: Text(Strings.settingsData)) {
                    Button(action: { viewModel.exportJSON() }) {
                        Label(Strings.settingsExportJSON, systemImage: "doc.text")
                    }

                    Button(action: { viewModel.exportText() }) {
                        Label(Strings.settingsExportText, systemImage: "doc.plaintext")
                    }

                    if let date = viewModel.preferences?.lastExportDate {
                        Text("Last export: \(date.formatted(date: .abbreviated, time: .shortened))")
                            .font(AppFont.captionSecondary)
                            .foregroundColor(AppColor.secondaryLabel)
                    }
                }

                // Delete All
                Section {
                    Button(role: .destructive, action: { viewModel.showDeleteConfirmation = true }) {
                        Label(Strings.settingsDeleteAll, systemImage: "trash")
                            .foregroundColor(AppColor.danger)
                    }
                }

                // About
                Section(header: Text(Strings.settingsAbout)) {
                    HStack {
                        Text(Strings.appName)
                        Spacer()
                        Text(Strings.appTagline)
                            .font(AppFont.caption)
                            .foregroundColor(AppColor.secondaryLabel)
                    }
                    HStack {
                        Text(Strings.settingsVersion)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(AppColor.secondaryLabel)
                    }
                }
            }
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
}

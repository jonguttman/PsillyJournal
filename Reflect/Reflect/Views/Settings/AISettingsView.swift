import SwiftUI

struct AISettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            // Enable/disable
            Section {
                Toggle(isOn: Binding(
                    get: { viewModel.preferences?.aiEnabled ?? false },
                    set: { newValue in
                        viewModel.preferences?.aiEnabled = newValue
                        viewModel.savePreferences()
                    }
                )) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(Strings.aiEnabled)
                            .font(AppFont.headline)
                        Text(Strings.aiDisabledNote)
                            .font(AppFont.captionSecondary)
                            .foregroundColor(AppColor.secondaryLabel)
                    }
                }
            }

            if viewModel.preferences?.aiEnabled == true {
                // Lens selection
                Section(header: Text("Active Lenses")) {
                    ForEach(LensType.allCases) { lens in
                        Toggle(isOn: lensBinding(for: lens)) {
                            HStack(spacing: Spacing.md) {
                                Image(systemName: lens.iconName)
                                    .foregroundColor(colorForLens(lens))
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: Spacing.xxs) {
                                    Text(lens.rawValue)
                                        .font(AppFont.headline)
                                    Text(lens.description)
                                        .font(AppFont.captionSecondary)
                                        .foregroundColor(AppColor.secondaryLabel)
                                }
                            }
                        }
                    }
                }

                // Tone
                Section(header: Text(Strings.settingsTone)) {
                    Picker("Tone", selection: Binding(
                        get: { viewModel.preferences?.tone ?? .gentle },
                        set: { newValue in
                            viewModel.preferences?.tone = newValue
                            viewModel.savePreferences()
                        }
                    )) {
                        ForEach(TonePreference.allCases) { tone in
                            Text(tone.displayName).tag(tone)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .navigationTitle(Strings.settingsAI)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func lensBinding(for lens: LensType) -> Binding<Bool> {
        Binding(
            get: {
                viewModel.preferences?.selectedLenses.contains(lens.rawValue) ?? false
            },
            set: { isEnabled in
                if isEnabled {
                    if !(viewModel.preferences?.selectedLenses.contains(lens.rawValue) ?? false) {
                        viewModel.preferences?.selectedLenses.append(lens.rawValue)
                    }
                } else {
                    viewModel.preferences?.selectedLenses.removeAll { $0 == lens.rawValue }
                }
                viewModel.savePreferences()
            }
        )
    }

    private func colorForLens(_ lens: LensType) -> Color {
        switch lens {
        case .grounding: return AppColor.groundingLens
        case .meaning: return AppColor.meaningLens
        case .integration: return AppColor.integrationLens
        }
    }
}

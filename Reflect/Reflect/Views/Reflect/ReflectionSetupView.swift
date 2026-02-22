import SwiftUI

struct ReflectionSetupView: View {
    @Bindable var viewModel: ReflectionViewModel
    @State private var voiceNotePath: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                Text(Strings.reflectSetupTitle)
                    .font(AppFont.title)
                    .foregroundColor(AppColor.label)

                Text("Take a moment to set the context for your reflection.")
                    .font(AppFont.body)
                    .foregroundColor(AppColor.secondaryLabel)

                // Title
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(Strings.reflectSessionTitle)
                        .font(AppFont.callout)
                        .foregroundColor(AppColor.label)
                    TextField("What are you reflecting on?", text: $viewModel.title)
                        .textFieldStyle(.roundedBorder)
                }

                // Intensity
                MetricSliderView(
                    label: Strings.reflectIntensity,
                    value: $viewModel.intensity,
                    range: 0...10,
                    color: AppColor.primary
                )

                // Environment
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(Strings.reflectEnvironment)
                        .font(AppFont.callout)
                        .foregroundColor(AppColor.label)
                    Picker("Environment", selection: $viewModel.environment) {
                        ForEach(ReflectionEnvironment.allCases) { env in
                            Text(env.rawValue).tag(env)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Support
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(Strings.reflectSupport)
                        .font(AppFont.callout)
                        .foregroundColor(AppColor.label)
                    Picker("Support", selection: $viewModel.support) {
                        ForEach(ReflectionSupport.allCases) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Themes
                TagPickerView(
                    title: Strings.reflectThemes,
                    allTags: ReflectionTheme.allCases,
                    selectedTags: $viewModel.themeTags
                )

                // Notes
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(Strings.reflectNotes)
                        .font(AppFont.callout)
                        .foregroundColor(AppColor.label)
                    TextEditor(text: $viewModel.notes)
                        .frame(minHeight: 60)
                        .padding(Spacing.xs)
                        .background(AppColor.tertiaryBackground)
                        .cornerRadius(CornerRadius.sm)
                }

                // Voice note
                VoiceNoteButton(voiceNotePath: $voiceNotePath)

                // Navigation
                HStack {
                    Button(Strings.cancel) {
                        viewModel.resetForm()
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button(action: {
                        viewModel.voiceNotePath = voiceNotePath
                        _ = viewModel.nextStep()
                    }) {
                        HStack {
                            Text(Strings.next)
                            Image(systemName: "arrow.right")
                        }
                        .font(AppFont.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, Spacing.md)
                        .background(viewModel.canProceed ? AppColor.primary : AppColor.secondaryLabel)
                        .cornerRadius(CornerRadius.md)
                    }
                    .disabled(!viewModel.canProceed)
                }
                .padding(.top, Spacing.md)
            }
            .padding(Spacing.lg)
        }
    }
}

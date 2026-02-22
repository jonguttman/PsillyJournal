import SwiftUI

struct ReflectionStepView: View {
    @Bindable var viewModel: ReflectionViewModel

    private var currentBinding: Binding<String> {
        switch viewModel.currentStep {
        case .capture: return $viewModel.captureResponse
        case .meaning: return $viewModel.meaningResponse
        case .nextStep: return $viewModel.nextStepResponse
        default: return .constant("")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            progressBar
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    // Step header
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Step \(viewModel.currentStep.rawValue) of 3")
                            .font(AppFont.caption)
                            .foregroundColor(AppColor.secondaryLabel)

                        Text(viewModel.currentStep.title)
                            .font(AppFont.title)
                            .foregroundColor(AppColor.label)
                    }

                    // Prompt
                    Text(viewModel.currentStep.prompt)
                        .font(AppFont.body)
                        .foregroundColor(AppColor.secondaryLabel)
                        .italic()
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColor.primary.opacity(0.05))
                        .cornerRadius(CornerRadius.md)

                    // Response text area
                    TextEditor(text: currentBinding)
                        .frame(minHeight: 200)
                        .padding(Spacing.sm)
                        .background(AppColor.tertiaryBackground)
                        .cornerRadius(CornerRadius.sm)
                        .overlay(
                            Group {
                                if currentBinding.wrappedValue.isEmpty {
                                    Text("Take your time. Write whatever comes to mind...")
                                        .foregroundColor(AppColor.secondaryLabel.opacity(0.5))
                                        .padding(Spacing.md)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )

                    // Navigation
                    HStack {
                        Button(action: { viewModel.previousStep() }) {
                            HStack {
                                Image(systemName: "arrow.left")
                                Text(Strings.back)
                            }
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        Button(action: { _ = viewModel.nextStep() }) {
                            HStack {
                                Text(viewModel.isLastInputStep ? "Review" : Strings.next)
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
        .alert(Strings.safetyBlockedTitle, isPresented: $viewModel.showSafetyAlert) {
            Button(Strings.done, role: .cancel) {}
        } message: {
            Text(viewModel.safetyAlertMessage)
        }
        .sheet(isPresented: $viewModel.showCrisisSheet) {
            CrisisResourcesView()
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        let steps = [ReflectionStep.capture, .meaning, .nextStep]
        let currentIndex = steps.firstIndex(of: viewModel.currentStep) ?? 0

        return HStack(spacing: Spacing.xs) {
            ForEach(0..<steps.count, id: \.self) { index in
                Capsule()
                    .fill(index <= currentIndex ? AppColor.primary : AppColor.secondaryLabel.opacity(0.3))
                    .frame(height: 4)
            }
        }
    }
}

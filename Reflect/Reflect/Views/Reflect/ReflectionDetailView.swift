import SwiftUI
import SwiftData

struct ReflectionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let session: ReflectionSession
    @Bindable var viewModel: ReflectionViewModel

    @State private var showSaveMomentSheet = false
    @State private var selectedTextForMoment = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    // Header
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(session.title)
                            .font(AppFont.largeTitle)
                            .foregroundColor(AppColor.label)

                        HStack(spacing: Spacing.md) {
                            Label(session.formattedDate, systemImage: "calendar")
                            Label("Intensity \(session.intensity)/10", systemImage: "flame")
                        }
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.secondaryLabel)
                    }

                    // Context
                    HStack(spacing: Spacing.lg) {
                        contextChip(icon: "house.fill", label: session.environment.rawValue)
                        contextChip(icon: "person.fill", label: session.support.rawValue)
                    }

                    // Themes
                    if !session.themeTags.isEmpty {
                        FlowLayout(spacing: Spacing.sm) {
                            ForEach(session.themeTags, id: \.self) { tag in
                                Text(tag)
                                    .font(AppFont.caption)
                                    .padding(.horizontal, Spacing.md)
                                    .padding(.vertical, Spacing.xs)
                                    .background(AppColor.primary.opacity(0.1))
                                    .cornerRadius(CornerRadius.xl)
                            }
                        }
                    }

                    Divider()

                    // Guided responses
                    reflectionSection(
                        title: Strings.reflectStepCaptureTitle,
                        prompt: Strings.reflectStepCapture,
                        response: session.captureResponse
                    )

                    reflectionSection(
                        title: Strings.reflectStepMeaningTitle,
                        prompt: Strings.reflectStepMeaning,
                        response: session.meaningResponse
                    )

                    reflectionSection(
                        title: Strings.reflectStepNextStepTitle,
                        prompt: Strings.reflectStepNextStep,
                        response: session.nextStepResponse
                    )

                    // Notes
                    if let notes = session.notes, !notes.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Notes")
                                .font(AppFont.headline)
                                .foregroundColor(AppColor.label)
                            Text(notes)
                                .font(AppFont.body)
                                .foregroundColor(AppColor.secondaryLabel)
                        }
                    }

                    // AI Lens Responses
                    if !viewModel.lensResponses.isEmpty {
                        Divider()
                        LensResponsesSection(responses: viewModel.lensResponses)
                    } else if viewModel.isGeneratingLens {
                        HStack(spacing: Spacing.sm) {
                            ProgressView()
                            Text("Generating reflections...")
                                .font(AppFont.caption)
                                .foregroundColor(AppColor.secondaryLabel)
                        }
                    }

                    // Save Moment button
                    Divider()
                    Button(action: { showSaveMomentSheet = true }) {
                        Label(Strings.momentsSaveCTA, systemImage: "sparkles")
                            .font(AppFont.headline)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(Spacing.lg)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.done) { dismiss() }
                }
            }
            .onAppear {
                viewModel.fetchLensResponses(for: session.id)
            }
            .sheet(isPresented: $showSaveMomentSheet) {
                SaveMomentView(
                    sourceType: .reflection,
                    sourceId: session.id,
                    prefilledQuote: String(session.captureResponse.prefix(240))
                )
            }
        }
    }

    // MARK: - Helpers

    private func reflectionSection(title: String, prompt: String, response: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(AppFont.headline)
                .foregroundColor(AppColor.label)

            Text(prompt)
                .font(AppFont.caption)
                .foregroundColor(AppColor.secondaryLabel)
                .italic()

            Text(response)
                .font(AppFont.body)
                .foregroundColor(AppColor.label)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func contextChip(icon: String, label: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.caption)
            Text(label)
                .font(AppFont.caption)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .background(AppColor.tertiaryBackground)
        .cornerRadius(CornerRadius.xl)
    }
}

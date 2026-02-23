import SwiftUI
import SwiftData

struct ReflectTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ReflectionViewModel()
    @State private var selectedSession: ReflectionSession?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isActive {
                    reflectionFlowView
                } else if viewModel.sessions.isEmpty {
                    emptyState
                } else {
                    sessionsList
                }
            }
            .warmBackground()
            .navigationTitle(Strings.reflectTitle)
            .toolbar {
                if !viewModel.isActive && !viewModel.sessions.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { viewModel.startNewSession() }) {
                            Image(systemName: "plus")
                                .foregroundColor(AppColor.amber)
                        }
                    }
                }
            }
            .onAppear { viewModel.setup(context: modelContext) }
            .sheet(item: $selectedSession) { session in
                ReflectionDetailView(session: session, viewModel: viewModel)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            icon: "brain.head.profile",
            title: Strings.reflectNoSessions,
            message: Strings.reflectNoSessionsBody,
            actionLabel: Strings.reflectStartCTA,
            action: { viewModel.startNewSession() }
        )
    }

    // MARK: - Sessions List

    private var sessionsList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                ForEach(viewModel.sessions, id: \.id) { session in
                    Button(action: { selectedSession = session }) {
                        sessionRow(session)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.sm)
            .padding(.bottom, 80)
        }
    }

    private func sessionRow(_ session: ReflectionSession) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .top) {
                Text(session.title)
                    .font(AppFont.headline)
                    .foregroundColor(AppColor.label)
                Spacer()
                Text("Intensity \(session.intensity)/10")
                    .font(AppFont.captionSecondary)
                    .foregroundColor(AppColor.clay)
            }

            Text(session.summary)
                .font(AppFont.body)
                .foregroundColor(AppColor.secondaryLabel)
                .lineLimit(2)

            HStack {
                Text(session.formattedDate)
                    .font(AppFont.captionSecondary)
                    .foregroundColor(AppColor.secondaryLabel)
                Spacer()
                if !session.themeTags.isEmpty {
                    HStack(spacing: Spacing.xs) {
                        ForEach(session.themeTags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(AppFont.captionSecondary)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xxs)
                                .background(AppColor.sage.opacity(0.12))
                                .foregroundColor(AppColor.sage)
                                .cornerRadius(CornerRadius.pill)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Reflection Flow

    private var reflectionFlowView: some View {
        VStack {
            switch viewModel.currentStep {
            case .setup:
                ReflectionSetupView(viewModel: viewModel)
            case .capture, .meaning, .nextStep:
                ReflectionStepView(viewModel: viewModel)
            case .review:
                reflectionReview
            }
        }
    }

    private var reflectionReview: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("Review Your Reflection")
                    .font(AppFont.title)
                    .foregroundColor(AppColor.label)

                Group {
                    reviewField("Title", value: viewModel.title)
                    reviewField("Intensity", value: "\(viewModel.intensity)/10")
                    reviewField("Environment", value: viewModel.environment.rawValue)
                    reviewField("Support", value: viewModel.support.rawValue)
                }

                Rectangle()
                    .fill(AppColor.separator.opacity(0.3))
                    .frame(height: 0.5)

                reviewField(Strings.reflectStepCaptureTitle, value: viewModel.captureResponse)
                reviewField(Strings.reflectStepMeaningTitle, value: viewModel.meaningResponse)
                reviewField(Strings.reflectStepNextStepTitle, value: viewModel.nextStepResponse)

                HStack(spacing: Spacing.md) {
                    Button(Strings.back) { viewModel.previousStep() }
                        .buttonStyle(.bordered)
                        .tint(AppColor.secondaryLabel)

                    Spacer()

                    Button(action: saveAndFinish) {
                        Text(Strings.save)
                            .font(AppFont.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, Spacing.xl)
                            .padding(.vertical, Spacing.md)
                            .background(AppGradient.warmCTA)
                            .cornerRadius(CornerRadius.lg)
                            .shadow(color: AppColor.amber.opacity(0.2), radius: 6, x: 0, y: 3)
                    }
                    .disabled(viewModel.isSaving)
                }
                .padding(.top, Spacing.md)
            }
            .padding(Spacing.lg)
        }
    }

    private func reviewField(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(label)
                .font(AppFont.caption)
                .foregroundColor(AppColor.amber.opacity(0.8))
            Text(value)
                .font(AppFont.body)
                .foregroundColor(AppColor.label)
        }
        .padding(.vertical, Spacing.xs)
    }

    private func saveAndFinish() {
        if viewModel.saveSession() {
            viewModel.resetForm()
        }
    }
}

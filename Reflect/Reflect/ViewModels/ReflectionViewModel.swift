import Foundation
import SwiftData
import SwiftUI

enum ReflectionStep: Int, CaseIterable {
    case setup = 0
    case capture = 1
    case meaning = 2
    case nextStep = 3
    case review = 4

    var title: String {
        switch self {
        case .setup: return "Setup"
        case .capture: return Strings.reflectStepCaptureTitle
        case .meaning: return Strings.reflectStepMeaningTitle
        case .nextStep: return Strings.reflectStepNextStepTitle
        case .review: return "Review"
        }
    }

    var prompt: String {
        switch self {
        case .setup: return ""
        case .capture: return Strings.reflectStepCapture
        case .meaning: return Strings.reflectStepMeaning
        case .nextStep: return Strings.reflectStepNextStep
        case .review: return ""
        }
    }
}

@MainActor
@Observable
final class ReflectionViewModel {
    // Session list
    var sessions: [ReflectionSession] = []

    // Current session being created
    var currentStep: ReflectionStep = .setup
    var title: String = ""
    var intensity: Int = 5
    var environment: ReflectionEnvironment = .home
    var support: ReflectionSupport = .solo
    var themeTags: [String] = []
    var notes: String = ""
    var voiceNotePath: String?

    // Guided step responses
    var captureResponse: String = ""
    var meaningResponse: String = ""
    var nextStepResponse: String = ""

    // AI
    var lensResponses: [LensResponse] = []
    var isGeneratingLens = false

    // UI state
    var showSafetyAlert = false
    var safetyAlertMessage = ""
    var showCrisisSheet = false
    var isActive = false  // true when in a session flow
    var isSaving = false

    private var modelContext: ModelContext?
    private var aiService: AIServiceProtocol = StubAIService()

    func setup(context: ModelContext) {
        self.modelContext = context
        fetchSessions()
    }

    func fetchSessions() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<ReflectionSession>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        sessions = (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Navigation

    func startNewSession() {
        resetForm()
        isActive = true
        currentStep = .setup
    }

    func nextStep() -> Bool {
        // Validate current step text with safety
        let textToCheck: String
        switch currentStep {
        case .capture: textToCheck = captureResponse
        case .meaning: textToCheck = meaningResponse
        case .nextStep: textToCheck = nextStepResponse
        default: textToCheck = ""
        }

        if !textToCheck.isEmpty {
            let result = SafetyService.checkContent(textToCheck)
            switch result {
            case .safe: break
            case .blocked(let reason):
                safetyAlertMessage = reason
                showSafetyAlert = true
                return false
            case .crisisDetected:
                showCrisisSheet = true
                return false
            }
        }

        if let nextIndex = ReflectionStep(rawValue: currentStep.rawValue + 1) {
            currentStep = nextIndex
            return true
        }
        return false
    }

    func previousStep() {
        if let prevIndex = ReflectionStep(rawValue: currentStep.rawValue - 1) {
            currentStep = prevIndex
        }
    }

    var canProceed: Bool {
        switch currentStep {
        case .setup: return !title.isEmpty
        case .capture: return !captureResponse.isEmpty
        case .meaning: return !meaningResponse.isEmpty
        case .nextStep: return !nextStepResponse.isEmpty
        case .review: return true
        }
    }

    var isFirstStep: Bool { currentStep == .setup }
    var isLastInputStep: Bool { currentStep == .nextStep }

    // MARK: - Save

    func saveSession() -> Bool {
        guard let context = modelContext else { return false }
        isSaving = true
        defer { isSaving = false }

        let session = ReflectionSession(
            title: title,
            intensity: intensity,
            environment: environment,
            support: support,
            themeTags: themeTags,
            notes: notes.isEmpty ? nil : notes,
            voiceNotePath: voiceNotePath,
            captureResponse: captureResponse,
            meaningResponse: meaningResponse,
            nextStepResponse: nextStepResponse
        )
        context.insert(session)

        do {
            try context.save()
            fetchSessions()
            return true
        } catch {
            return false
        }
    }

    func deleteSession(_ session: ReflectionSession) -> Bool {
        guard let context = modelContext else { return false }
        context.delete(session)
        do {
            try context.save()
            fetchSessions()
            return true
        } catch {
            return false
        }
    }

    // MARK: - AI Lens

    func generateLensResponses(for session: ReflectionSession, preferences: UserPreferences) {
        guard preferences.aiEnabled else { return }
        guard let context = modelContext else { return }

        isGeneratingLens = true
        let entryText = """
        Title: \(session.title)
        Capture: \(session.captureResponse)
        Meaning: \(session.meaningResponse)
        Next Step: \(session.nextStepResponse)
        """

        Task {
            var responses: [LensResponse] = []
            for lensType in preferences.activeLensTypes {
                do {
                    let content = try await aiService.generateLensResponse(
                        entryText: entryText,
                        lensType: lensType,
                        tone: preferences.tone,
                        avoidTopics: preferences.avoidTopics
                    )
                    let response = LensResponse(
                        entryType: .reflection,
                        entryId: session.id,
                        lensType: lensType,
                        content: content
                    )
                    context.insert(response)
                    responses.append(response)
                } catch {
                    // Individual lens failure — skip, don't block others
                }
            }
            try? context.save()
            lensResponses = responses
            isGeneratingLens = false
        }
    }

    func fetchLensResponses(for sessionId: UUID) {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<LensResponse>(
            predicate: #Predicate { $0.entryId == sessionId }
        )
        lensResponses = (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Reset

    func resetForm() {
        currentStep = .setup
        title = ""
        intensity = 5
        environment = .home
        support = .solo
        themeTags = []
        notes = ""
        voiceNotePath = nil
        captureResponse = ""
        meaningResponse = ""
        nextStepResponse = ""
        lensResponses = []
        isActive = false
    }
}

import Foundation

// MARK: - AI Service Protocol

/// Interface for AI-powered reflection lens responses.
/// All implementations must pass output through SafetyService before returning.
protocol AIServiceProtocol {
    /// Generates a lens response for a given entry.
    func generateLensResponse(
        entryText: String,
        lensType: LensType,
        tone: TonePreference,
        avoidTopics: [String]
    ) async throws -> String
}

// MARK: - Errors

enum AIServiceError: Error, LocalizedError {
    case aiDisabled
    case generationFailed
    case contentFiltered

    var errorDescription: String? {
        switch self {
        case .aiDisabled: return "AI reflections are disabled."
        case .generationFailed: return "Could not generate a response. Please try again."
        case .contentFiltered: return "The response was filtered for safety. Please try a different reflection."
        }
    }
}

// MARK: - Stub AI Service

/// Local stub provider with canned responses. No network calls.
/// Serves as the default when no real API is configured.
struct StubAIService: AIServiceProtocol {
    func generateLensResponse(
        entryText: String,
        lensType: LensType,
        tone: TonePreference,
        avoidTopics: [String]
    ) async throws -> String {
        // Simulate a brief delay for realism
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5s

        let raw: String
        switch lensType {
        case .grounding:
            raw = groundingResponse(tone: tone)
        case .meaning:
            raw = meaningResponse(tone: tone)
        case .integration:
            raw = integrationResponse(tone: tone)
        }

        // Always filter output through safety layer
        let filtered = SafetyService.filterAIOutput(raw)
        return filtered
    }

    // MARK: - Canned Responses

    private func groundingResponse(tone: TonePreference) -> String {
        switch tone {
        case .gentle:
            return """
            Take a moment to notice where you are right now. Feel your feet on the ground, \
            your breath moving in and out. Whatever came up in your reflection is worth \
            honoring — there's no rush to make sense of it all at once.

            A few gentle reminders:
            • Drink some water and take a few slow breaths.
            • If it feels right, step outside for a moment of fresh air.
            • Consider sharing what's on your mind with someone you trust.
            • Rest is a form of self-care — it's okay to take things slowly.
            """
        case .direct:
            return """
            Ground yourself: notice your body, your breath, your surroundings. \
            What you reflected on matters — sit with it without forcing conclusions.

            Practical self-care steps:
            • Hydrate and move your body, even briefly.
            • Get outside if you can.
            • Talk to someone you trust about what's on your mind.
            • Prioritize rest tonight.
            """
        }
    }

    private func meaningResponse(tone: TonePreference) -> String {
        switch tone {
        case .gentle:
            return """
            Here are a few possible threads your reflection might be pointing toward. \
            Hold them lightly — these are invitations to explore, not answers:

            1. This could be highlighting something you've been carrying for a while — \
            a feeling or question that's been waiting for your attention.

            2. It might be connected to a relationship or connection in your life that's \
            shifting or asking for something new.

            3. There could be a creative or expressive impulse here — something that wants \
            to be made, written, or shared.

            Which of these resonates, even a little?
            """
        case .direct:
            return """
            Three possible interpretations of what came up:

            1. You might be processing something that's been unresolved — this reflection \
            could be your way of finally turning toward it.

            2. There could be a pattern here: a recurring theme in how you relate to \
            others or to yourself.

            3. This might be pointing toward something you want to create or change — \
            an impulse worth following.

            Consider which feels most true right now.
            """
        }
    }

    private func integrationResponse(tone: TonePreference) -> String {
        switch tone {
        case .gentle:
            return """
            Here's a gentle 7-day plan to help you carry this reflection forward:

            🌱 Daily habit (Days 1–7):
            Spend 5 minutes each morning writing one sentence about how you're feeling. \
            No pressure to be profound — just honest.

            🤝 Relationship step (by Day 4):
            Reach out to someone who came to mind during your reflection. A simple \
            message or a shared walk — whatever feels right.

            ✨ Creative step (by Day 7):
            Express something from this experience in a way that feels natural to you — \
            a sketch, a playlist, a poem, a photo, a conversation. Let the form find you.

            Remember: integration is not about perfection. It's about small, consistent \
            acts of attention.
            """
        case .direct:
            return """
            A 7-day integration plan based on your reflection:

            📝 Daily habit (Days 1–7):
            Write one sentence each morning about how you're feeling. Keep it simple.

            👥 Relationship step (by Day 4):
            Contact someone who came to mind. Share something real, even if it's brief.

            🎨 Creative step (by Day 7):
            Turn part of this experience into something tangible — writing, art, music, \
            a conversation. Pick the medium that comes naturally.

            Consistency matters more than intensity. Show up each day.
            """
        }
    }
}

// MARK: - Live AI Service (Placeholder)

/// Placeholder for real API integration.
/// TODO: Implement with actual API calls (e.g., Claude, OpenAI).
struct LiveAIService: AIServiceProtocol {
    func generateLensResponse(
        entryText: String,
        lensType: LensType,
        tone: TonePreference,
        avoidTopics: [String]
    ) async throws -> String {
        // TODO: Replace with actual API call.
        // The implementation should:
        // 1. Build a prompt incorporating entryText, lensType, tone, and avoidTopics
        // 2. Call the AI API
        // 3. Pass the response through SafetyService.filterAIOutput()
        // 4. Return the filtered result
        //
        // For now, fall back to stub:
        let stub = StubAIService()
        return try await stub.generateLensResponse(
            entryText: entryText,
            lensType: lensType,
            tone: tone,
            avoidTopics: avoidTopics
        )
    }
}

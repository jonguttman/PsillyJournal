import Foundation

// MARK: - Safety Result

enum SafetyResult: Equatable {
    case safe
    case blocked(reason: String)
    case crisisDetected
}

// MARK: - Safety Service

/// Local safety layer that checks content for disallowed material and detects crisis signals.
/// This service runs entirely on-device with no network calls.
struct SafetyService {

    // MARK: - Disallowed Content Patterns

    /// Keywords/phrases that indicate requests for dosing, illegal activity, or medical treatment.
    static let disallowedPatterns: [String] = [
        // Substance-related
        "dosage", "dosing", "microdose", "macrodose", "how much to take",
        "how to take", "where to buy", "where to get", "how to source",
        "how to grow", "how to extract", "how to synthesize",
        "trip report", "trip sit", "set and setting",
        // Specific substances (common)
        "psilocybin", "lsd", "dmt", "mdma", "ayahuasca", "mescaline",
        "ketamine", "cocaine", "heroin", "methamphetamine", "fentanyl",
        "magic mushroom", "shroom",
        // Medical claims
        "cure for", "treatment for", "prescribe", "prescription",
        "diagnose", "diagnosis", "medical advice",
        // Illegal activity
        "how to hide", "how to smuggle", "avoid detection",
        "fake prescription", "dark web", "darknet",
    ]

    /// Keywords/phrases that indicate self-harm or suicidal ideation.
    static let crisisPatterns: [String] = [
        "kill myself", "want to die", "end my life", "suicide",
        "suicidal", "self-harm", "self harm", "hurt myself",
        "don't want to live", "not worth living", "better off dead",
        "no reason to live", "can't go on", "end it all",
        "cut myself", "cutting myself", "overdose",
        "plan to end", "goodbye letter", "final letter",
    ]

    // MARK: - Content Checking

    /// Checks user-provided text for disallowed content or crisis signals.
    static func checkContent(_ text: String) -> SafetyResult {
        let lowered = text.lowercased()

        // Check for crisis signals first (highest priority)
        for pattern in crisisPatterns {
            if lowered.contains(pattern) {
                return .crisisDetected
            }
        }

        // Check for disallowed content
        for pattern in disallowedPatterns {
            if lowered.contains(pattern) {
                return .blocked(
                    reason: "Content related to \(categorizeBlocked(pattern)) is not supported."
                )
            }
        }

        return .safe
    }

    /// Filters AI-generated output. Returns cleaned text or a safe fallback.
    static func filterAIOutput(_ text: String) -> String {
        let lowered = text.lowercased()

        // If AI output contains crisis-related content, return fallback
        for pattern in crisisPatterns {
            if lowered.contains(pattern) {
                return SafetyService.safeFallbackResponse
            }
        }

        // If AI output contains disallowed content, return fallback
        for pattern in disallowedPatterns {
            if lowered.contains(pattern) {
                return SafetyService.safeFallbackResponse
            }
        }

        return text
    }

    // MARK: - Fallback

    static let safeFallbackResponse = """
    Thank you for sharing. Take a moment to notice how you're feeling right now. \
    Whatever you're experiencing is valid. Consider what small, kind action you \
    could take for yourself today.
    """

    // MARK: - Helpers

    private static func categorizeBlocked(_ pattern: String) -> String {
        let substanceKeywords = [
            "dosage", "dosing", "microdose", "macrodose", "take", "buy", "source",
            "grow", "extract", "synthesize", "trip", "psilocybin", "lsd", "dmt",
            "mdma", "ayahuasca", "mescaline", "ketamine", "cocaine", "heroin",
            "methamphetamine", "fentanyl", "mushroom", "shroom", "set and setting",
        ]
        let medicalKeywords = [
            "cure", "treatment", "prescribe", "prescription", "diagnose", "diagnosis",
            "medical advice",
        ]

        if substanceKeywords.contains(where: { pattern.contains($0) }) {
            return "substances or dosing guidance"
        }
        if medicalKeywords.contains(where: { pattern.contains($0) }) {
            return "medical advice or treatment"
        }
        return "prohibited topics"
    }
}

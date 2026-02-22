import Foundation
import SwiftData

// MARK: - Supporting Enums

enum ReflectionEnvironment: String, Codable, CaseIterable, Identifiable {
    case home = "Home"
    case outdoors = "Outdoors"
    case quietSpace = "Quiet Space"
    case other = "Other"

    var id: String { rawValue }
}

enum ReflectionSupport: String, Codable, CaseIterable, Identifiable {
    case solo = "Solo"
    case trustedPerson = "Trusted Person"
    case professional = "Professional Setting"

    var id: String { rawValue }
}

// MARK: - Model

@Model
final class ReflectionSession {
    var id: UUID
    var title: String
    var intensity: Int  // 0–10
    var environment: ReflectionEnvironment
    var support: ReflectionSupport
    var themeTags: [String]
    var notes: String?
    var voiceNotePath: String?

    // Guided step responses
    var captureResponse: String   // "What stands out most?"
    var meaningResponse: String   // "What might this be pointing to?"
    var nextStepResponse: String  // "One small action?"

    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "",
        intensity: Int = 5,
        environment: ReflectionEnvironment = .home,
        support: ReflectionSupport = .solo,
        themeTags: [String] = [],
        notes: String? = nil,
        voiceNotePath: String? = nil,
        captureResponse: String = "",
        meaningResponse: String = "",
        nextStepResponse: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.intensity = intensity
        self.environment = environment
        self.support = support
        self.themeTags = themeTags
        self.notes = notes
        self.voiceNotePath = voiceNotePath
        self.captureResponse = captureResponse
        self.meaningResponse = meaningResponse
        self.nextStepResponse = nextStepResponse
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Convenience

extension ReflectionSession {
    var formattedDate: String {
        createdAt.formatted(date: .abbreviated, time: .shortened)
    }

    var isComplete: Bool {
        !captureResponse.isEmpty && !meaningResponse.isEmpty && !nextStepResponse.isEmpty
    }

    var summary: String {
        if !captureResponse.isEmpty {
            return String(captureResponse.prefix(100))
        }
        return title
    }
}

// MARK: - Common Theme Tags

enum ReflectionTheme: String, CaseIterable, Identifiable {
    case growth = "Growth"
    case relationships = "Relationships"
    case creativity = "Creativity"
    case purpose = "Purpose"
    case loss = "Loss"
    case gratitude = "Gratitude"
    case change = "Change"
    case identity = "Identity"
    case nature = "Nature"
    case wonder = "Wonder"
    case challenge = "Challenge"
    case connection = "Connection"

    var id: String { rawValue }
}

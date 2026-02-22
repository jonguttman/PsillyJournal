import Foundation
import SwiftData

enum TonePreference: String, Codable, CaseIterable, Identifiable {
    case gentle = "gentle"
    case direct = "direct"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gentle: return Strings.lensToneGentle
        case .direct: return Strings.lensToneDirect
        }
    }
}

@Model
final class UserPreferences {
    var id: UUID
    var aiEnabled: Bool
    var selectedLenses: [String]  // LensType raw values
    var tone: TonePreference
    var avoidTopics: [String]
    var appLockEnabled: Bool
    var lastExportDate: Date?
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        aiEnabled: Bool = false,
        selectedLenses: [String] = LensType.allCases.map(\.rawValue),
        tone: TonePreference = .gentle,
        avoidTopics: [String] = [],
        appLockEnabled: Bool = false,
        lastExportDate: Date? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.aiEnabled = aiEnabled
        self.selectedLenses = selectedLenses
        self.tone = tone
        self.avoidTopics = avoidTopics
        self.appLockEnabled = appLockEnabled
        self.lastExportDate = lastExportDate
        self.updatedAt = updatedAt
    }
}

// MARK: - Convenience

extension UserPreferences {
    var activeLensTypes: [LensType] {
        selectedLenses.compactMap { LensType(rawValue: $0) }
    }
}

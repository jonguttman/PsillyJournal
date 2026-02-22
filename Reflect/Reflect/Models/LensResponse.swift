import Foundation
import SwiftData

enum LensType: String, Codable, CaseIterable, Identifiable {
    case grounding = "Grounding"
    case meaning = "Meaning"
    case integration = "Integration"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .grounding: return Strings.lensGroundingDesc
        case .meaning: return Strings.lensMeaningDesc
        case .integration: return Strings.lensIntegrationDesc
        }
    }

    var iconName: String {
        switch self {
        case .grounding: return "leaf.fill"
        case .meaning: return "sparkles"
        case .integration: return "arrow.triangle.merge"
        }
    }
}

enum EntryType: String, Codable {
    case checkIn = "checkIn"
    case reflection = "reflection"
}

@Model
final class LensResponse {
    var id: UUID
    var entryType: EntryType
    var entryId: UUID
    var lensType: LensType
    var content: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        entryType: EntryType,
        entryId: UUID,
        lensType: LensType,
        content: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.entryType = entryType
        self.entryId = entryId
        self.lensType = lensType
        self.content = content
        self.createdAt = createdAt
    }
}

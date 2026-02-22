import Foundation
import SwiftData

enum MomentSourceType: String, Codable {
    case checkIn = "checkIn"
    case reflection = "reflection"
}

@Model
final class Moment {
    var id: UUID
    var quote: String           // <= 240 characters
    var themes: [String]
    var emotions: [String]
    var intensity: Int          // 0–10
    var askOfMe: String         // "What this asks of me" — one line
    var sourceType: MomentSourceType
    var sourceId: UUID
    var createdAt: Date

    init(
        id: UUID = UUID(),
        quote: String = "",
        themes: [String] = [],
        emotions: [String] = [],
        intensity: Int = 5,
        askOfMe: String = "",
        sourceType: MomentSourceType = .checkIn,
        sourceId: UUID = UUID(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.quote = String(quote.prefix(240))
        self.themes = themes
        self.emotions = emotions
        self.intensity = intensity
        self.askOfMe = askOfMe
        self.sourceType = sourceType
        self.sourceId = sourceId
        self.createdAt = createdAt
    }
}

// MARK: - Convenience

extension Moment {
    var formattedDate: String {
        createdAt.formatted(date: .abbreviated, time: .omitted)
    }
}

// MARK: - Common Emotion Tags

enum EmotionTag: String, CaseIterable, Identifiable {
    case joy = "Joy"
    case sadness = "Sadness"
    case peace = "Peace"
    case awe = "Awe"
    case love = "Love"
    case fear = "Fear"
    case anger = "Anger"
    case hope = "Hope"
    case confusion = "Confusion"
    case gratitude = "Gratitude"
    case curiosity = "Curiosity"
    case tenderness = "Tenderness"

    var id: String { rawValue }
}

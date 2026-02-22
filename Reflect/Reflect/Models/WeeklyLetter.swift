import Foundation
import SwiftData

@Model
final class WeeklyLetter {
    var id: UUID
    var startDate: Date
    var endDate: Date
    var themes: [String]        // Top 3 themes
    var moments: String         // Summary of 3 key moments
    var questions: String       // 2 gentle questions
    var commitment: String      // 1 small commitment
    var fullText: String        // Complete rendered letter
    var createdAt: Date

    init(
        id: UUID = UUID(),
        startDate: Date = Date(),
        endDate: Date = Date(),
        themes: [String] = [],
        moments: String = "",
        questions: String = "",
        commitment: String = "",
        fullText: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.themes = themes
        self.moments = moments
        self.questions = questions
        self.commitment = commitment
        self.fullText = fullText
        self.createdAt = createdAt
    }
}

// MARK: - Convenience

extension WeeklyLetter {
    var dateRangeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: startDate)) – \(formatter.string(from: endDate))"
    }
}

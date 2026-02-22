import Foundation
import SwiftData

@Model
final class CheckIn {
    var id: UUID
    var mood: Int          // 1–10
    var energy: Int        // 1–10
    var stress: Int        // 1–10
    var sleepHours: Double
    var sleepQuality: Int  // 1–10
    var note: String?
    var voiceNotePath: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        mood: Int = 5,
        energy: Int = 5,
        stress: Int = 5,
        sleepHours: Double = 7.0,
        sleepQuality: Int = 5,
        note: String? = nil,
        voiceNotePath: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.mood = mood
        self.energy = energy
        self.stress = stress
        self.sleepHours = sleepHours
        self.sleepQuality = sleepQuality
        self.note = note
        self.voiceNotePath = voiceNotePath
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Convenience

extension CheckIn {
    var isToday: Bool {
        Calendar.current.isDateInToday(createdAt)
    }

    var formattedDate: String {
        createdAt.formatted(date: .abbreviated, time: .shortened)
    }

    var averageWellbeing: Double {
        let moodNorm = Double(mood)
        let energyNorm = Double(energy)
        let stressInv = Double(11 - stress) // invert: low stress = high wellbeing
        let sleepNorm = Double(sleepQuality)
        return (moodNorm + energyNorm + stressInv + sleepNorm) / 4.0
    }
}

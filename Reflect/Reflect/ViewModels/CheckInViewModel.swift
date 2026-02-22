import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class CheckInViewModel {
    // Form state
    var mood: Int = 5
    var energy: Int = 5
    var stress: Int = 5
    var sleepHours: Double = 7.0
    var sleepQuality: Int = 5
    var note: String = ""
    var voiceNotePath: String?

    // UI state
    var showSafetyAlert = false
    var safetyAlertMessage = ""
    var showCrisisSheet = false
    var isSaving = false

    // Editing
    var editingCheckIn: CheckIn?
    var isEditing: Bool { editingCheckIn != nil }

    private var modelContext: ModelContext?

    func setup(context: ModelContext) {
        self.modelContext = context
    }

    /// Populate form from an existing check-in for editing.
    func loadForEditing(_ checkIn: CheckIn) {
        editingCheckIn = checkIn
        mood = checkIn.mood
        energy = checkIn.energy
        stress = checkIn.stress
        sleepHours = checkIn.sleepHours
        sleepQuality = checkIn.sleepQuality
        note = checkIn.note ?? ""
        voiceNotePath = checkIn.voiceNotePath
    }

    /// Reset form to defaults.
    func resetForm() {
        editingCheckIn = nil
        mood = 5
        energy = 5
        stress = 5
        sleepHours = 7.0
        sleepQuality = 5
        note = ""
        voiceNotePath = nil
    }

    /// Validates and saves the check-in. Returns true on success.
    func save() -> Bool {
        guard let context = modelContext else { return false }
        isSaving = true
        defer { isSaving = false }

        // Safety check on note text
        if !note.isEmpty {
            let result = SafetyService.checkContent(note)
            switch result {
            case .safe:
                break
            case .blocked(let reason):
                safetyAlertMessage = reason
                showSafetyAlert = true
                return false
            case .crisisDetected:
                showCrisisSheet = true
                return false
            }
        }

        if let existing = editingCheckIn {
            // Update existing
            existing.mood = mood
            existing.energy = energy
            existing.stress = stress
            existing.sleepHours = sleepHours
            existing.sleepQuality = sleepQuality
            existing.note = note.isEmpty ? nil : note
            existing.voiceNotePath = voiceNotePath
            existing.updatedAt = Date()
        } else {
            // Create new
            let checkIn = CheckIn(
                mood: mood,
                energy: energy,
                stress: stress,
                sleepHours: sleepHours,
                sleepQuality: sleepQuality,
                note: note.isEmpty ? nil : note,
                voiceNotePath: voiceNotePath
            )
            context.insert(checkIn)
        }

        do {
            try context.save()
            return true
        } catch {
            return false
        }
    }

    /// Delete a check-in.
    func delete(_ checkIn: CheckIn) -> Bool {
        guard let context = modelContext else { return false }
        context.delete(checkIn)
        do {
            try context.save()
            return true
        } catch {
            return false
        }
    }
}

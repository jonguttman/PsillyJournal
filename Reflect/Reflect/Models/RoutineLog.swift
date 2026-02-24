// Reflect/Models/RoutineLog.swift
import Foundation
import SwiftData

@Model
final class RoutineLog {
    var id: UUID
    var routineEntry: RoutineEntry?
    var loggedAt: Date
    var skipped: Bool
    var note: String?

    init(
        routineEntry: RoutineEntry,
        loggedAt: Date = Date(),
        skipped: Bool = false,
        note: String? = nil
    ) {
        self.id = UUID()
        self.routineEntry = routineEntry
        self.loggedAt = loggedAt
        self.skipped = skipped
        self.note = note
    }
}

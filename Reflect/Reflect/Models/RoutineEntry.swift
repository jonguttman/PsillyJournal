// Reflect/Models/RoutineEntry.swift
import Foundation
import SwiftData

enum RoutineSchedule: String, Codable, CaseIterable {
    case daily
    case weekly
    case asNeeded
    case custom

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .asNeeded: return "As Needed"
        case .custom: return "Custom"
        }
    }
}

@Model
final class RoutineEntry {
    var id: UUID
    var product: VerifiedProduct?
    var scheduleRaw: String
    var scheduleDays: [Int]?
    var reminderTime: Date?
    var reminderEnabled: Bool
    var notes: String?
    var linkedAt: Date
    var isActive: Bool

    var schedule: RoutineSchedule {
        get { RoutineSchedule(rawValue: scheduleRaw) ?? .daily }
        set { scheduleRaw = newValue.rawValue }
    }

    init(
        product: VerifiedProduct,
        schedule: RoutineSchedule = .daily,
        scheduleDays: [Int]? = nil,
        reminderTime: Date? = nil,
        reminderEnabled: Bool = false,
        notes: String? = nil,
        linkedAt: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.product = product
        self.scheduleRaw = schedule.rawValue
        self.scheduleDays = scheduleDays
        self.reminderTime = reminderTime
        self.reminderEnabled = reminderEnabled
        self.notes = notes
        self.linkedAt = linkedAt
        self.isActive = isActive
    }
}

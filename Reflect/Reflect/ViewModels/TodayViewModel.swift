import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class TodayViewModel {
    var todayCheckIn: CheckIn?
    var recentCheckIns: [CheckIn] = []
    var recentMoment: Moment?
    var showCheckInForm = false

    private var modelContext: ModelContext?

    func setup(context: ModelContext) {
        self.modelContext = context
        refresh()
    }

    func refresh() {
        guard let context = modelContext else { return }

        // Today's check-in
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        var todayDescriptor = FetchDescriptor<CheckIn>(
            predicate: #Predicate { $0.createdAt >= startOfDay && $0.createdAt < endOfDay },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        todayDescriptor.fetchLimit = 1
        todayCheckIn = try? context.fetch(todayDescriptor).first

        // Recent check-ins (last 7)
        var recentDescriptor = FetchDescriptor<CheckIn>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        recentDescriptor.fetchLimit = 7
        recentCheckIns = (try? context.fetch(recentDescriptor)) ?? []

        // Most recent moment
        var momentDescriptor = FetchDescriptor<Moment>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        momentDescriptor.fetchLimit = 1
        recentMoment = try? context.fetch(momentDescriptor).first
    }

    var hasCheckedInToday: Bool {
        todayCheckIn != nil
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Hello"
        }
    }
}

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class InsightsViewModel {
    var recentCheckIns: [CheckIn] = []
    var allSessions: [ReflectionSession] = []
    var allMoments: [Moment] = []
    var weeklyLetters: [WeeklyLetter] = []
    var currentLetter: WeeklyLetter?

    var isGeneratingLetter = false

    private var modelContext: ModelContext?

    func setup(context: ModelContext) {
        self.modelContext = context
        refresh()
    }

    func refresh() {
        guard let context = modelContext else { return }

        // Last 7 days of check-ins
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        var checkInDescriptor = FetchDescriptor<CheckIn>(
            predicate: #Predicate { $0.createdAt >= sevenDaysAgo },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        checkInDescriptor.fetchLimit = 50
        recentCheckIns = (try? context.fetch(checkInDescriptor)) ?? []

        // All sessions (for letter)
        let sessionDescriptor = FetchDescriptor<ReflectionSession>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        allSessions = (try? context.fetch(sessionDescriptor)) ?? []

        // All moments (for letter)
        let momentDescriptor = FetchDescriptor<Moment>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        allMoments = (try? context.fetch(momentDescriptor)) ?? []

        // Existing weekly letters
        let letterDescriptor = FetchDescriptor<WeeklyLetter>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        weeklyLetters = (try? context.fetch(letterDescriptor)) ?? []
        currentLetter = weeklyLetters.first
    }

    // MARK: - Trend Data

    var hasEnoughData: Bool {
        recentCheckIns.count >= 2
    }

    var averageMood: Double {
        guard !recentCheckIns.isEmpty else { return 0 }
        return Double(recentCheckIns.map(\.mood).reduce(0, +)) / Double(recentCheckIns.count)
    }

    var averageEnergy: Double {
        guard !recentCheckIns.isEmpty else { return 0 }
        return Double(recentCheckIns.map(\.energy).reduce(0, +)) / Double(recentCheckIns.count)
    }

    var averageStress: Double {
        guard !recentCheckIns.isEmpty else { return 0 }
        return Double(recentCheckIns.map(\.stress).reduce(0, +)) / Double(recentCheckIns.count)
    }

    var averageSleep: Double {
        guard !recentCheckIns.isEmpty else { return 0 }
        return recentCheckIns.map(\.sleepHours).reduce(0, +) / Double(recentCheckIns.count)
    }

    var averageSleepQuality: Double {
        guard !recentCheckIns.isEmpty else { return 0 }
        return Double(recentCheckIns.map(\.sleepQuality).reduce(0, +)) / Double(recentCheckIns.count)
    }

    /// Daily values for the last 7 days (for simple chart display).
    struct DailyMetric: Identifiable {
        let id = UUID()
        let date: Date
        let mood: Double
        let energy: Double
        let stress: Double
        let sleepQuality: Double

        var dayLabel: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        }
    }

    var dailyMetrics: [DailyMetric] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var metrics: [DailyMetric] = []

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let nextDate = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            let dayCheckIns = recentCheckIns.filter { $0.createdAt >= date && $0.createdAt < nextDate }

            if dayCheckIns.isEmpty {
                metrics.append(DailyMetric(date: date, mood: 0, energy: 0, stress: 0, sleepQuality: 0))
            } else {
                let count = Double(dayCheckIns.count)
                metrics.append(DailyMetric(
                    date: date,
                    mood: Double(dayCheckIns.map(\.mood).reduce(0, +)) / count,
                    energy: Double(dayCheckIns.map(\.energy).reduce(0, +)) / count,
                    stress: Double(dayCheckIns.map(\.stress).reduce(0, +)) / count,
                    sleepQuality: Double(dayCheckIns.map(\.sleepQuality).reduce(0, +)) / count
                ))
            }
        }
        return metrics
    }

    // MARK: - Weekly Letter

    func generateWeeklyLetter() {
        guard let context = modelContext else { return }
        isGeneratingLetter = true

        let letter = WeeklyLetterService.generateLetterForLastWeek(
            checkIns: recentCheckIns,
            sessions: allSessions,
            moments: allMoments
        )
        context.insert(letter)
        try? context.save()

        currentLetter = letter
        weeklyLetters.insert(letter, at: 0)
        isGeneratingLetter = false
    }

    func regenerateWeeklyLetter() {
        // Delete current and regenerate
        if let current = currentLetter, let context = modelContext {
            context.delete(current)
            try? context.save()
        }
        generateWeeklyLetter()
    }
}

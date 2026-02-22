import Foundation

/// Generates weekly reflection letters from stored journal data.
/// Pure local logic — no AI required.
struct WeeklyLetterService {

    /// Generates a weekly letter for the given date range.
    static func generateLetter(
        checkIns: [CheckIn],
        sessions: [ReflectionSession],
        moments: [Moment],
        startDate: Date,
        endDate: Date
    ) -> WeeklyLetter {
        // Filter to date range
        let rangeCheckIns = checkIns.filter { $0.createdAt >= startDate && $0.createdAt <= endDate }
        let rangeSessions = sessions.filter { $0.createdAt >= startDate && $0.createdAt <= endDate }
        let rangeMoments = moments.filter { $0.createdAt >= startDate && $0.createdAt <= endDate }

        // Extract themes
        let themes = extractTopThemes(sessions: rangeSessions, moments: rangeMoments)

        // Pick key moments
        let keyMoments = pickKeyMoments(
            checkIns: rangeCheckIns,
            sessions: rangeSessions,
            moments: rangeMoments
        )

        // Generate questions
        let questions = generateQuestions(themes: themes, checkIns: rangeCheckIns)

        // Generate commitment
        let commitment = generateCommitment(themes: themes, sessions: rangeSessions)

        // Compose full text
        let fullText = composeLetter(
            startDate: startDate,
            endDate: endDate,
            themes: themes,
            keyMoments: keyMoments,
            questions: questions,
            commitment: commitment,
            checkIns: rangeCheckIns,
            sessions: rangeSessions
        )

        return WeeklyLetter(
            startDate: startDate,
            endDate: endDate,
            themes: themes,
            moments: keyMoments,
            questions: questions,
            commitment: commitment,
            fullText: fullText
        )
    }

    /// Convenience: generates for the last 7 days.
    static func generateLetterForLastWeek(
        checkIns: [CheckIn],
        sessions: [ReflectionSession],
        moments: [Moment]
    ) -> WeeklyLetter {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        return generateLetter(
            checkIns: checkIns,
            sessions: sessions,
            moments: moments,
            startDate: startDate,
            endDate: endDate
        )
    }

    // MARK: - Theme Extraction

    static func extractTopThemes(
        sessions: [ReflectionSession],
        moments: [Moment]
    ) -> [String] {
        var frequency: [String: Int] = [:]

        for session in sessions {
            for tag in session.themeTags {
                frequency[tag, default: 0] += 1
            }
        }
        for moment in moments {
            for theme in moment.themes {
                frequency[theme, default: 0] += 1
            }
            for emotion in moment.emotions {
                frequency[emotion, default: 0] += 1
            }
        }

        // Return top 3 by frequency
        let sorted = frequency.sorted { $0.value > $1.value }
        return Array(sorted.prefix(3).map(\.key))
    }

    // MARK: - Key Moments

    static func pickKeyMoments(
        checkIns: [CheckIn],
        sessions: [ReflectionSession],
        moments: [Moment]
    ) -> String {
        var picks: [String] = []

        // From saved moments (prefer these)
        for m in moments.prefix(2) {
            picks.append("• \"\(m.quote)\"")
        }

        // From sessions
        for s in sessions.prefix(2) {
            if !s.captureResponse.isEmpty && picks.count < 3 {
                let snippet = String(s.captureResponse.prefix(120))
                picks.append("• From \"\(s.title)\": \(snippet)")
            }
        }

        // From check-in notes
        if picks.count < 3 {
            for c in checkIns where c.note != nil && !c.note!.isEmpty {
                if picks.count < 3 {
                    picks.append("• \(c.note!)")
                }
            }
        }

        if picks.isEmpty {
            return "No specific moments captured this week — and that's okay."
        }

        return picks.prefix(3).joined(separator: "\n")
    }

    // MARK: - Questions

    static func generateQuestions(themes: [String], checkIns: [CheckIn]) -> String {
        var questions: [String] = []

        // Theme-based question
        if let firstTheme = themes.first {
            questions.append("What is \(firstTheme.lowercased()) asking of you right now?")
        }

        // Metric-based question
        if !checkIns.isEmpty {
            let avgMood = Double(checkIns.map(\.mood).reduce(0, +)) / Double(checkIns.count)
            let avgStress = Double(checkIns.map(\.stress).reduce(0, +)) / Double(checkIns.count)
            if avgStress > 6 {
                questions.append("Your stress has been elevated this week. What's one thing you could let go of, even temporarily?")
            } else if avgMood < 5 {
                questions.append("Your mood has been lower this week. What's one thing that usually lifts your spirits?")
            } else {
                questions.append("What contributed most to the good moments this week? How could you invite more of that?")
            }
        }

        // Fallback
        if questions.isEmpty {
            questions.append("What felt most meaningful this week?")
            questions.append("What do you want to carry forward into next week?")
        }

        return questions.prefix(2).enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
    }

    // MARK: - Commitment

    static func generateCommitment(themes: [String], sessions: [ReflectionSession]) -> String {
        // Use the most recent session's next step if available
        if let latest = sessions.sorted(by: { $0.createdAt > $1.createdAt }).first,
           !latest.nextStepResponse.isEmpty {
            return String(latest.nextStepResponse.prefix(200))
        }

        // Theme-based fallback
        if let theme = themes.first {
            return "This week, I'll pay attention to how \(theme.lowercased()) shows up in my daily life."
        }

        return "This week, I'll take five quiet minutes each day to check in with myself."
    }

    // MARK: - Letter Composition

    static func composeLetter(
        startDate: Date,
        endDate: Date,
        themes: [String],
        keyMoments: String,
        questions: String,
        commitment: String,
        checkIns: [CheckIn],
        sessions: [ReflectionSession]
    ) -> String {
        let dateFmt = DateFormatter()
        dateFmt.dateStyle = .medium

        var lines: [String] = []

        lines.append("Dear Self,")
        lines.append("")

        // Opening summary
        let checkInCount = checkIns.count
        let sessionCount = sessions.count
        var openingParts: [String] = []
        if checkInCount > 0 {
            openingParts.append("\(checkInCount) daily check-in\(checkInCount == 1 ? "" : "s")")
        }
        if sessionCount > 0 {
            openingParts.append("\(sessionCount) reflection session\(sessionCount == 1 ? "" : "s")")
        }
        if openingParts.isEmpty {
            lines.append("This was a quieter week for journaling, and that's perfectly fine. Sometimes the pauses are where the growth happens.")
        } else {
            lines.append("This week (\(dateFmt.string(from: startDate)) – \(dateFmt.string(from: endDate))), you showed up with \(openingParts.joined(separator: " and ")). Here's what stood out:")
        }
        lines.append("")

        // Themes
        if !themes.isEmpty {
            lines.append("✦ Themes This Week")
            for theme in themes {
                lines.append("  • \(theme)")
            }
            lines.append("")
        }

        // Key Moments
        lines.append("✦ Key Moments")
        lines.append(keyMoments)
        lines.append("")

        // Metrics snapshot
        if !checkIns.isEmpty {
            let avgMood = String(format: "%.1f", Double(checkIns.map(\.mood).reduce(0, +)) / Double(checkIns.count))
            let avgEnergy = String(format: "%.1f", Double(checkIns.map(\.energy).reduce(0, +)) / Double(checkIns.count))
            let avgStress = String(format: "%.1f", Double(checkIns.map(\.stress).reduce(0, +)) / Double(checkIns.count))
            lines.append("✦ How You've Been")
            lines.append("  Mood: \(avgMood)/10  Energy: \(avgEnergy)/10  Stress: \(avgStress)/10")
            lines.append("")
        }

        // Questions
        lines.append("✦ Questions to Sit With")
        lines.append(questions)
        lines.append("")

        // Commitment
        lines.append("✦ A Small Commitment")
        lines.append(commitment)
        lines.append("")

        // Closing
        lines.append("With care,")
        lines.append("Your Reflect Journal")

        return lines.joined(separator: "\n")
    }
}

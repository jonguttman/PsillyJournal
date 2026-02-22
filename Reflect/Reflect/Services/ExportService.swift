import Foundation

/// Exports journal data to JSON and plain text formats.
struct ExportService {

    // MARK: - Codable DTOs

    struct ExportCheckIn: Codable {
        let id: String
        let mood: Int
        let energy: Int
        let stress: Int
        let sleepHours: Double
        let sleepQuality: Int
        let note: String?
        let createdAt: String
    }

    struct ExportSession: Codable {
        let id: String
        let title: String
        let intensity: Int
        let environment: String
        let support: String
        let themes: [String]
        let notes: String?
        let captureResponse: String
        let meaningResponse: String
        let nextStepResponse: String
        let createdAt: String
    }

    struct ExportMoment: Codable {
        let id: String
        let quote: String
        let themes: [String]
        let emotions: [String]
        let intensity: Int
        let askOfMe: String
        let createdAt: String
    }

    struct ExportLetter: Codable {
        let id: String
        let dateRange: String
        let themes: [String]
        let moments: String
        let questions: String
        let commitment: String
        let fullText: String
        let createdAt: String
    }

    struct ExportBundle: Codable {
        let exportedAt: String
        let appName: String
        let checkIns: [ExportCheckIn]
        let reflectionSessions: [ExportSession]
        let moments: [ExportMoment]
        let weeklyLetters: [ExportLetter]
    }

    // MARK: - JSON Export

    static func exportToJSON(
        checkIns: [CheckIn],
        sessions: [ReflectionSession],
        moments: [Moment],
        letters: [WeeklyLetter]
    ) throws -> Data {
        let iso = ISO8601DateFormatter()
        let bundle = ExportBundle(
            exportedAt: iso.string(from: Date()),
            appName: Strings.appName,
            checkIns: checkIns.map {
                ExportCheckIn(
                    id: $0.id.uuidString,
                    mood: $0.mood, energy: $0.energy, stress: $0.stress,
                    sleepHours: $0.sleepHours, sleepQuality: $0.sleepQuality,
                    note: $0.note,
                    createdAt: iso.string(from: $0.createdAt)
                )
            },
            reflectionSessions: sessions.map {
                ExportSession(
                    id: $0.id.uuidString,
                    title: $0.title, intensity: $0.intensity,
                    environment: $0.environment.rawValue,
                    support: $0.support.rawValue,
                    themes: $0.themeTags, notes: $0.notes,
                    captureResponse: $0.captureResponse,
                    meaningResponse: $0.meaningResponse,
                    nextStepResponse: $0.nextStepResponse,
                    createdAt: iso.string(from: $0.createdAt)
                )
            },
            moments: moments.map {
                ExportMoment(
                    id: $0.id.uuidString,
                    quote: $0.quote, themes: $0.themes,
                    emotions: $0.emotions, intensity: $0.intensity,
                    askOfMe: $0.askOfMe,
                    createdAt: iso.string(from: $0.createdAt)
                )
            },
            weeklyLetters: letters.map {
                ExportLetter(
                    id: $0.id.uuidString,
                    dateRange: $0.dateRangeFormatted,
                    themes: $0.themes, moments: $0.moments,
                    questions: $0.questions, commitment: $0.commitment,
                    fullText: $0.fullText,
                    createdAt: iso.string(from: $0.createdAt)
                )
            }
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(bundle)
    }

    // MARK: - Text Export

    static func exportToText(
        checkIns: [CheckIn],
        sessions: [ReflectionSession],
        moments: [Moment],
        letters: [WeeklyLetter]
    ) -> String {
        var lines: [String] = []
        let dateFmt = DateFormatter()
        dateFmt.dateStyle = .medium
        dateFmt.timeStyle = .short

        lines.append("═══════════════════════════════════")
        lines.append("  REFLECT — Your Journal Export")
        lines.append("  Exported: \(dateFmt.string(from: Date()))")
        lines.append("═══════════════════════════════════")
        lines.append("")

        // Check-ins
        if !checkIns.isEmpty {
            lines.append("── DAILY CHECK-INS ──")
            lines.append("")
            for c in checkIns.sorted(by: { $0.createdAt > $1.createdAt }) {
                lines.append("[\(dateFmt.string(from: c.createdAt))]")
                lines.append("  Mood: \(c.mood)/10  Energy: \(c.energy)/10  Stress: \(c.stress)/10")
                lines.append("  Sleep: \(String(format: "%.1f", c.sleepHours))h  Quality: \(c.sleepQuality)/10")
                if let note = c.note, !note.isEmpty {
                    lines.append("  Note: \(note)")
                }
                lines.append("")
            }
        }

        // Sessions
        if !sessions.isEmpty {
            lines.append("── REFLECTION SESSIONS ──")
            lines.append("")
            for s in sessions.sorted(by: { $0.createdAt > $1.createdAt }) {
                lines.append("[\(dateFmt.string(from: s.createdAt))] \(s.title)")
                lines.append("  Intensity: \(s.intensity)/10  Environment: \(s.environment.rawValue)  Support: \(s.support.rawValue)")
                if !s.themeTags.isEmpty {
                    lines.append("  Themes: \(s.themeTags.joined(separator: ", "))")
                }
                if !s.captureResponse.isEmpty {
                    lines.append("  Capture: \(s.captureResponse)")
                }
                if !s.meaningResponse.isEmpty {
                    lines.append("  Meaning: \(s.meaningResponse)")
                }
                if !s.nextStepResponse.isEmpty {
                    lines.append("  Next Step: \(s.nextStepResponse)")
                }
                lines.append("")
            }
        }

        // Moments
        if !moments.isEmpty {
            lines.append("── MOMENTS ──")
            lines.append("")
            for m in moments.sorted(by: { $0.createdAt > $1.createdAt }) {
                lines.append("[\(dateFmt.string(from: m.createdAt))]")
                lines.append("  \"\(m.quote)\"")
                if !m.themes.isEmpty {
                    lines.append("  Themes: \(m.themes.joined(separator: ", "))")
                }
                if !m.emotions.isEmpty {
                    lines.append("  Emotions: \(m.emotions.joined(separator: ", "))")
                }
                if !m.askOfMe.isEmpty {
                    lines.append("  What this asks of me: \(m.askOfMe)")
                }
                lines.append("")
            }
        }

        // Weekly Letters
        if !letters.isEmpty {
            lines.append("── WEEKLY REFLECTION LETTERS ──")
            lines.append("")
            for l in letters.sorted(by: { $0.createdAt > $1.createdAt }) {
                lines.append("[\(l.dateRangeFormatted)]")
                lines.append(l.fullText)
                lines.append("")
                lines.append("---")
                lines.append("")
            }
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - File Helpers

    /// Writes data to a temporary file and returns the URL for sharing.
    static func writeToTempFile(data: Data, filename: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        try data.write(to: fileURL)
        return fileURL
    }

    /// Writes text to a temporary file and returns the URL for sharing.
    static func writeToTempFile(text: String, filename: String) throws -> URL {
        let data = Data(text.utf8)
        return try writeToTempFile(data: data, filename: filename)
    }
}

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class SettingsViewModel {
    var preferences: UserPreferences?

    // Export state
    var isExporting = false
    var exportURL: URL?
    var showShareSheet = false
    var exportError: String?

    // Delete all
    var showDeleteConfirmation = false
    var isDeleting = false

    private var modelContext: ModelContext?

    func setup(context: ModelContext) {
        self.modelContext = context
        loadPreferences()
    }

    func loadPreferences() {
        guard let context = modelContext else { return }
        let persistence = PersistenceService.shared
        preferences = persistence.getOrCreatePreferences(context: context)
    }

    func savePreferences() {
        guard let context = modelContext, let prefs = preferences else { return }
        prefs.updatedAt = Date()
        try? context.save()
    }

    // MARK: - Avoid Topics

    var avoidTopicsText: String {
        get { preferences?.avoidTopics.joined(separator: ", ") ?? "" }
        set {
            preferences?.avoidTopics = newValue
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            savePreferences()
        }
    }

    // MARK: - Export

    func exportJSON() {
        guard let context = modelContext else { return }
        isExporting = true
        defer { isExporting = false }

        do {
            let checkIns = try context.fetch(FetchDescriptor<CheckIn>())
            let sessions = try context.fetch(FetchDescriptor<ReflectionSession>())
            let moments = try context.fetch(FetchDescriptor<Moment>())
            let letters = try context.fetch(FetchDescriptor<WeeklyLetter>())

            let data = try ExportService.exportToJSON(
                checkIns: checkIns, sessions: sessions,
                moments: moments, letters: letters
            )
            exportURL = try ExportService.writeToTempFile(
                data: data, filename: "reflect_export.json"
            )
            preferences?.lastExportDate = Date()
            savePreferences()
            showShareSheet = true
        } catch {
            exportError = error.localizedDescription
        }
    }

    func exportText() {
        guard let context = modelContext else { return }
        isExporting = true
        defer { isExporting = false }

        do {
            let checkIns = try context.fetch(FetchDescriptor<CheckIn>())
            let sessions = try context.fetch(FetchDescriptor<ReflectionSession>())
            let moments = try context.fetch(FetchDescriptor<Moment>())
            let letters = try context.fetch(FetchDescriptor<WeeklyLetter>())

            let text = ExportService.exportToText(
                checkIns: checkIns, sessions: sessions,
                moments: moments, letters: letters
            )
            exportURL = try ExportService.writeToTempFile(
                text: text, filename: "reflect_export.txt"
            )
            preferences?.lastExportDate = Date()
            savePreferences()
            showShareSheet = true
        } catch {
            exportError = error.localizedDescription
        }
    }

    // MARK: - Delete All

    func deleteAllData() {
        guard let context = modelContext else { return }
        isDeleting = true
        defer { isDeleting = false }

        do {
            try PersistenceService.shared.deleteAllData(context: context)
            preferences = nil
            loadPreferences()
        } catch {
            exportError = "Failed to delete data: \(error.localizedDescription)"
        }
    }
}

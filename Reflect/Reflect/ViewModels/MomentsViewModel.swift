import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class MomentsViewModel {
    var moments: [Moment] = []
    var filteredMoments: [Moment] = []

    // Filter state
    var filterTag: String? = nil
    var filterSourceType: MomentSourceType? = nil
    var searchText: String = "" {
        didSet { applyFilters() }
    }

    // Save moment form state
    var quote: String = ""
    var themes: [String] = []
    var emotions: [String] = []
    var intensity: Int = 5
    var askOfMe: String = ""

    // UI state
    var showSaveMomentSheet = false
    var savingSourceType: MomentSourceType = .checkIn
    var savingSourceId: UUID = UUID()

    private var modelContext: ModelContext?

    func setup(context: ModelContext) {
        self.modelContext = context
        fetchMoments()
    }

    func fetchMoments() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<Moment>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        moments = (try? context.fetch(descriptor)) ?? []
        applyFilters()
    }

    // MARK: - Filtering

    func applyFilters() {
        var result = moments

        if let tag = filterTag {
            result = result.filter { $0.themes.contains(tag) || $0.emotions.contains(tag) }
        }

        if let sourceType = filterSourceType {
            result = result.filter { $0.sourceType == sourceType }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.quote.lowercased().contains(query) ||
                $0.askOfMe.lowercased().contains(query) ||
                $0.themes.contains(where: { $0.lowercased().contains(query) }) ||
                $0.emotions.contains(where: { $0.lowercased().contains(query) })
            }
        }

        filteredMoments = result
    }

    func clearFilters() {
        filterTag = nil
        filterSourceType = nil
        searchText = ""
        applyFilters()
    }

    /// All unique tags across moments (for filter chips).
    var allTags: [String] {
        var tags = Set<String>()
        for moment in moments {
            tags.formUnion(moment.themes)
            tags.formUnion(moment.emotions)
        }
        return tags.sorted()
    }

    // MARK: - Save Moment

    func prepareSaveMoment(sourceType: MomentSourceType, sourceId: UUID, prefilledQuote: String = "") {
        savingSourceType = sourceType
        savingSourceId = sourceId
        quote = String(prefilledQuote.prefix(240))
        themes = []
        emotions = []
        intensity = 5
        askOfMe = ""
        showSaveMomentSheet = true
    }

    func saveMoment() -> Bool {
        guard let context = modelContext else { return false }
        guard !quote.isEmpty else { return false }

        let moment = Moment(
            quote: String(quote.prefix(240)),
            themes: themes,
            emotions: emotions,
            intensity: intensity,
            askOfMe: askOfMe,
            sourceType: savingSourceType,
            sourceId: savingSourceId
        )
        context.insert(moment)

        do {
            try context.save()
            fetchMoments()
            showSaveMomentSheet = false
            return true
        } catch {
            return false
        }
    }

    func deleteMoment(_ moment: Moment) -> Bool {
        guard let context = modelContext else { return false }
        context.delete(moment)
        do {
            try context.save()
            fetchMoments()
            return true
        } catch {
            return false
        }
    }
}

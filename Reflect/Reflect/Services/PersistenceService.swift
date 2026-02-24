import Foundation
import SwiftData

/// Configures the SwiftData ModelContainer and provides data management utilities.
@MainActor
final class PersistenceService {
    static let shared = PersistenceService()

    let container: ModelContainer

    private init() {
        let schema = Schema([
            CheckIn.self,
            ReflectionSession.self,
            Moment.self,
            WeeklyLetter.self,
            LensResponse.self,
            UserPreferences.self,
            VerifiedProduct.self,
            PendingToken.self,
            RoutineEntry.self,
            RoutineLog.self,
        ])
        let config = ModelConfiguration(
            "Reflect",
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    /// Creates an in-memory container for previews and tests.
    static func previewContainer() -> ModelContainer {
        let schema = Schema([
            CheckIn.self,
            ReflectionSession.self,
            Moment.self,
            WeeklyLetter.self,
            LensResponse.self,
            UserPreferences.self,
            VerifiedProduct.self,
            PendingToken.self,
            RoutineEntry.self,
            RoutineLog.self,
        ])
        let config = ModelConfiguration(
            "ReflectPreview",
            schema: schema,
            isStoredInMemoryOnly: true
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create preview ModelContainer: \(error)")
        }
    }

    /// Irreversibly deletes all data from every model.
    func deleteAllData(context: ModelContext) throws {
        try context.delete(model: CheckIn.self)
        try context.delete(model: ReflectionSession.self)
        try context.delete(model: Moment.self)
        try context.delete(model: WeeklyLetter.self)
        try context.delete(model: LensResponse.self)
        try context.delete(model: UserPreferences.self)
        try context.delete(model: VerifiedProduct.self)
        try context.delete(model: PendingToken.self)
        try context.delete(model: RoutineEntry.self)
        try context.delete(model: RoutineLog.self)
        try context.save()
    }

    /// Fetches or creates the singleton UserPreferences.
    func getOrCreatePreferences(context: ModelContext) -> UserPreferences {
        let descriptor = FetchDescriptor<UserPreferences>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let prefs = UserPreferences()
        context.insert(prefs)
        try? context.save()
        return prefs
    }
}

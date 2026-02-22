import XCTest
import SwiftData
@testable import Reflect

final class ModelTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    @MainActor
    override func setUp() {
        super.setUp()
        container = PersistenceService.previewContainer()
        context = container.mainContext
    }

    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }

    // MARK: - CheckIn CRUD

    @MainActor
    func testCreateCheckIn() throws {
        let checkIn = CheckIn(mood: 7, energy: 6, stress: 3, sleepHours: 8.0, sleepQuality: 8)
        context.insert(checkIn)
        try context.save()

        let descriptor = FetchDescriptor<CheckIn>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.mood, 7)
        XCTAssertEqual(results.first?.energy, 6)
        XCTAssertEqual(results.first?.stress, 3)
    }

    @MainActor
    func testUpdateCheckIn() throws {
        let checkIn = CheckIn(mood: 5, energy: 5, stress: 5)
        context.insert(checkIn)
        try context.save()

        checkIn.mood = 8
        checkIn.note = "Feeling better"
        try context.save()

        let descriptor = FetchDescriptor<CheckIn>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.first?.mood, 8)
        XCTAssertEqual(results.first?.note, "Feeling better")
    }

    @MainActor
    func testDeleteCheckIn() throws {
        let checkIn = CheckIn()
        context.insert(checkIn)
        try context.save()

        context.delete(checkIn)
        try context.save()

        let descriptor = FetchDescriptor<CheckIn>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 0)
    }

    @MainActor
    func testCheckInAverageWellbeing() {
        let checkIn = CheckIn(mood: 8, energy: 6, stress: 2, sleepQuality: 7)
        // wellbeing = (8 + 6 + (11-2) + 7) / 4 = (8 + 6 + 9 + 7) / 4 = 30/4 = 7.5
        XCTAssertEqual(checkIn.averageWellbeing, 7.5)
    }

    // MARK: - ReflectionSession CRUD

    @MainActor
    func testCreateReflectionSession() throws {
        let session = ReflectionSession(
            title: "Morning walk reflection",
            intensity: 6,
            environment: .outdoors,
            support: .solo,
            themeTags: ["Nature", "Gratitude"],
            captureResponse: "The trees were so still.",
            meaningResponse: "I need more quiet moments.",
            nextStepResponse: "Walk every morning this week."
        )
        context.insert(session)
        try context.save()

        let descriptor = FetchDescriptor<ReflectionSession>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Morning walk reflection")
        XCTAssertEqual(results.first?.environment, .outdoors)
        XCTAssertTrue(results.first?.isComplete ?? false)
    }

    @MainActor
    func testSessionIsComplete() {
        let incomplete = ReflectionSession(title: "Test", captureResponse: "Something")
        XCTAssertFalse(incomplete.isComplete)

        let complete = ReflectionSession(
            title: "Test",
            captureResponse: "A",
            meaningResponse: "B",
            nextStepResponse: "C"
        )
        XCTAssertTrue(complete.isComplete)
    }

    @MainActor
    func testDeleteReflectionSession() throws {
        let session = ReflectionSession(title: "To delete")
        context.insert(session)
        try context.save()

        context.delete(session)
        try context.save()

        let descriptor = FetchDescriptor<ReflectionSession>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 0)
    }

    // MARK: - Moment CRUD

    @MainActor
    func testCreateMoment() throws {
        let moment = Moment(
            quote: "The silence between the notes is where the music lives.",
            themes: ["Wonder"],
            emotions: ["Awe", "Peace"],
            intensity: 7,
            askOfMe: "Listen more carefully",
            sourceType: .reflection,
            sourceId: UUID()
        )
        context.insert(moment)
        try context.save()

        let descriptor = FetchDescriptor<Moment>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.emotions.count, 2)
    }

    @MainActor
    func testMomentQuoteTruncation() {
        let longQuote = String(repeating: "a", count: 300)
        let moment = Moment(quote: longQuote)
        XCTAssertEqual(moment.quote.count, 240)
    }

    @MainActor
    func testDeleteMoment() throws {
        let moment = Moment(quote: "To delete")
        context.insert(moment)
        try context.save()

        context.delete(moment)
        try context.save()

        let descriptor = FetchDescriptor<Moment>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 0)
    }

    // MARK: - WeeklyLetter CRUD

    @MainActor
    func testCreateWeeklyLetter() throws {
        let letter = WeeklyLetter(
            themes: ["Growth", "Connection"],
            moments: "Key moment 1\nKey moment 2",
            questions: "1. What matters?\n2. What's next?",
            commitment: "Be more present",
            fullText: "Dear Self, ..."
        )
        context.insert(letter)
        try context.save()

        let descriptor = FetchDescriptor<WeeklyLetter>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.themes.count, 2)
    }

    // MARK: - LensResponse CRUD

    @MainActor
    func testCreateLensResponse() throws {
        let response = LensResponse(
            entryType: .reflection,
            entryId: UUID(),
            lensType: .grounding,
            content: "Take a deep breath..."
        )
        context.insert(response)
        try context.save()

        let descriptor = FetchDescriptor<LensResponse>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.lensType, .grounding)
    }

    // MARK: - UserPreferences

    @MainActor
    func testUserPreferencesDefaults() {
        let prefs = UserPreferences()
        XCTAssertFalse(prefs.aiEnabled)
        XCTAssertEqual(prefs.tone, .gentle)
        XCTAssertTrue(prefs.avoidTopics.isEmpty)
        XCTAssertFalse(prefs.appLockEnabled)
        XCTAssertEqual(prefs.activeLensTypes.count, LensType.allCases.count)
    }

    @MainActor
    func testUserPreferencesPersistence() throws {
        let prefs = UserPreferences(aiEnabled: true, tone: .direct, avoidTopics: ["work", "family"])
        context.insert(prefs)
        try context.save()

        let descriptor = FetchDescriptor<UserPreferences>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.first?.aiEnabled, true)
        XCTAssertEqual(results.first?.tone, .direct)
        XCTAssertEqual(results.first?.avoidTopics, ["work", "family"])
    }
}

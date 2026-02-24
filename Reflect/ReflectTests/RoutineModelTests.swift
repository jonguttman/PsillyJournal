// ReflectTests/RoutineModelTests.swift
import XCTest
import SwiftData
@testable import Reflect

final class RoutineModelTests: XCTestCase {

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

    // MARK: - RoutineSchedule enum

    func testRoutineScheduleRawValues() {
        XCTAssertEqual(RoutineSchedule.daily.rawValue, "daily")
        XCTAssertEqual(RoutineSchedule.weekly.rawValue, "weekly")
        XCTAssertEqual(RoutineSchedule.asNeeded.rawValue, "asNeeded")
        XCTAssertEqual(RoutineSchedule.custom.rawValue, "custom")
    }

    // MARK: - RoutineEntry

    @MainActor
    func testCreateRoutineEntry() throws {
        let product = VerifiedProduct(
            productId: "prod_abc",
            token: "qr_test1234567890abcdef",
            name: "Test Product",
            category: "Supplement"
        )
        context.insert(product)

        let entry = RoutineEntry(product: product, schedule: .daily)
        context.insert(entry)
        try context.save()

        let descriptor = FetchDescriptor<RoutineEntry>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.schedule, .daily)
        XCTAssertTrue(results.first?.isActive ?? false)
        XCTAssertEqual(results.first?.product?.name, "Test Product")
    }

    @MainActor
    func testRoutineEntryWeeklySchedule() throws {
        let product = VerifiedProduct(
            productId: "prod_abc",
            token: "qr_test1234567890abcdef",
            name: "Test",
            category: "Test"
        )
        context.insert(product)

        let entry = RoutineEntry(
            product: product,
            schedule: .weekly,
            scheduleDays: [1, 3, 5],
            reminderTime: Date(),
            reminderEnabled: true
        )
        context.insert(entry)
        try context.save()

        let descriptor = FetchDescriptor<RoutineEntry>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.first?.scheduleDays, [1, 3, 5])
        XCTAssertTrue(results.first?.reminderEnabled ?? false)
    }

    @MainActor
    func testDeactivateRoutineEntry() throws {
        let product = VerifiedProduct(
            productId: "prod_abc",
            token: "qr_test1234567890abcdef",
            name: "Test",
            category: "Test"
        )
        context.insert(product)

        let entry = RoutineEntry(product: product, schedule: .daily)
        context.insert(entry)

        entry.isActive = false
        try context.save()

        let descriptor = FetchDescriptor<RoutineEntry>()
        let results = try context.fetch(descriptor)
        XCTAssertFalse(results.first?.isActive ?? true)
    }

    // MARK: - RoutineLog

    @MainActor
    func testCreateRoutineLog() throws {
        let product = VerifiedProduct(
            productId: "prod_abc",
            token: "qr_test1234567890abcdef",
            name: "Test",
            category: "Test"
        )
        context.insert(product)

        let entry = RoutineEntry(product: product, schedule: .daily)
        context.insert(entry)

        let log = RoutineLog(routineEntry: entry)
        context.insert(log)
        try context.save()

        let descriptor = FetchDescriptor<RoutineLog>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 1)
        XCTAssertFalse(results.first?.skipped ?? true)
        XCTAssertEqual(results.first?.routineEntry?.id, entry.id)
    }

    @MainActor
    func testLogSkipped() throws {
        let product = VerifiedProduct(
            productId: "prod_abc",
            token: "qr_test1234567890abcdef",
            name: "Test",
            category: "Test"
        )
        context.insert(product)

        let entry = RoutineEntry(product: product, schedule: .daily)
        context.insert(entry)

        let log = RoutineLog(routineEntry: entry, skipped: true, note: "Not today")
        context.insert(log)
        try context.save()

        let descriptor = FetchDescriptor<RoutineLog>()
        let results = try context.fetch(descriptor)
        XCTAssertTrue(results.first?.skipped ?? false)
        XCTAssertEqual(results.first?.note, "Not today")
    }
}

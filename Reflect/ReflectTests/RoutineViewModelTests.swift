// ReflectTests/RoutineViewModelTests.swift
import XCTest
import SwiftData
@testable import Reflect

final class RoutineViewModelTests: XCTestCase {

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

    // MARK: - Scan Flow

    @MainActor
    func testParseScanResultValid() {
        let vm = RoutineViewModel()
        vm.setup(context: context)

        let result = vm.processScanResult("https://link.reflectapp.com/t/qr_POcQ38aDUKrqeyFQJibNKK")
        XCTAssertEqual(result, "qr_POcQ38aDUKrqeyFQJibNKK")
        XCTAssertNil(vm.scanError)
    }

    @MainActor
    func testParseScanResultInvalidDomain() {
        let vm = RoutineViewModel()
        vm.setup(context: context)

        let result = vm.processScanResult("https://evil.com/t/qr_POcQ38aDUKrqeyFQJibNKK")
        XCTAssertNil(result)
        XCTAssertEqual(vm.scanError, .invalidQR)
    }

    // MARK: - Routine CRUD

    @MainActor
    func testLinkProductToRoutine() throws {
        let vm = RoutineViewModel()
        vm.setup(context: context)

        let product = VerifiedProduct(
            productId: "prod_abc",
            token: "qr_testProduct12345678abcd",
            name: "Test",
            category: "Test"
        )
        context.insert(product)
        try context.save()

        let entry = vm.addToRoutine(product: product, schedule: .daily)
        try context.save()

        XCTAssertNotNil(entry)
        XCTAssertEqual(entry.schedule, .daily)
        XCTAssertTrue(entry.isActive)
    }

    @MainActor
    func testLogRoutineEntry() throws {
        let vm = RoutineViewModel()
        vm.setup(context: context)

        let product = VerifiedProduct(
            productId: "prod_abc",
            token: "qr_testProduct12345678abcd",
            name: "Test",
            category: "Test"
        )
        context.insert(product)

        let entry = RoutineEntry(product: product, schedule: .daily)
        context.insert(entry)
        try context.save()

        let log = vm.logEntry(entry, skipped: false, note: "Taken with breakfast")
        try context.save()

        XCTAssertNotNil(log)
        XCTAssertFalse(log.skipped)
        XCTAssertEqual(log.note, "Taken with breakfast")
    }

    @MainActor
    func testSkipRoutineEntry() throws {
        let vm = RoutineViewModel()
        vm.setup(context: context)

        let product = VerifiedProduct(
            productId: "prod_abc",
            token: "qr_testProduct12345678abcd",
            name: "Test",
            category: "Test"
        )
        context.insert(product)

        let entry = RoutineEntry(product: product, schedule: .daily)
        context.insert(entry)
        try context.save()

        let log = vm.logEntry(entry, skipped: true)
        XCTAssertTrue(log.skipped)
    }

    @MainActor
    func testFetchActiveRoutines() throws {
        let vm = RoutineViewModel()
        vm.setup(context: context)

        let product = VerifiedProduct(
            productId: "prod_abc",
            token: "qr_testProduct12345678abcd",
            name: "Test",
            category: "Test"
        )
        context.insert(product)

        let active = RoutineEntry(product: product, schedule: .daily, isActive: true)
        let inactive = RoutineEntry(product: product, schedule: .daily, isActive: false)
        context.insert(active)
        context.insert(inactive)
        try context.save()

        vm.refresh()
        XCTAssertEqual(vm.activeEntries.count, 1)
    }

    // MARK: - Adherence

    @MainActor
    func testWeeklyAdherence() throws {
        let vm = RoutineViewModel()
        vm.setup(context: context)

        let product = VerifiedProduct(
            productId: "prod_abc",
            token: "qr_testProduct12345678abcd",
            name: "Test",
            category: "Test"
        )
        context.insert(product)

        let entry = RoutineEntry(product: product, schedule: .daily)
        context.insert(entry)

        // Log 3 of the last 7 days
        let calendar = Calendar.current
        for daysAgo in [0, 2, 4] {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
            let log = RoutineLog(routineEntry: entry, loggedAt: date)
            context.insert(log)
        }
        try context.save()

        let adherence = vm.weeklyAdherence(for: entry)
        XCTAssertEqual(adherence.logged, 3)
        XCTAssertEqual(adherence.expected, 7)
    }
}

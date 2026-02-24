// ReflectTests/VerifiedProductTests.swift
import XCTest
import SwiftData
@testable import Reflect

final class VerifiedProductTests: XCTestCase {

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

    // MARK: - VerifiedProduct

    @MainActor
    func testCreateVerifiedProduct() throws {
        let product = VerifiedProduct(
            productId: "prod_abc123",
            token: "qr_POcQ38aDUKrqeyFQJibNKK",
            name: "Chamomile Calm Blend",
            category: "Herbal Tea",
            productDescription: "A soothing herbal tea blend.",
            batchId: "batch_2024Q1_042",
            verifiedAt: Date()
        )
        context.insert(product)
        try context.save()

        let descriptor = FetchDescriptor<VerifiedProduct>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Chamomile Calm Blend")
        XCTAssertEqual(results.first?.category, "Herbal Tea")
        XCTAssertEqual(results.first?.status, .active)
    }

    @MainActor
    func testVerifiedProductCacheStaleness() {
        let product = VerifiedProduct(
            productId: "prod_abc",
            token: "qr_test1234567890abcdef",
            name: "Test",
            category: "Test"
        )
        // Default TTL is 86400 (24h), cachedAt is now → not stale
        XCTAssertFalse(product.isCacheStale)

        // Set cachedAt to 25 hours ago → stale
        product.cachedAt = Date().addingTimeInterval(-90000)
        XCTAssertTrue(product.isCacheStale)
    }

    @MainActor
    func testVerifiedProductRevocation() throws {
        let product = VerifiedProduct(
            productId: "prod_abc",
            token: "qr_test1234567890abcdef",
            name: "Test",
            category: "Test"
        )
        context.insert(product)
        XCTAssertEqual(product.status, .active)

        product.status = .revoked
        try context.save()

        let descriptor = FetchDescriptor<VerifiedProduct>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.first?.status, .revoked)
    }

    // MARK: - PendingToken

    @MainActor
    func testCreatePendingToken() throws {
        let pending = PendingToken(token: "qr_offlineTest12345678ab")
        context.insert(pending)
        try context.save()

        let descriptor = FetchDescriptor<PendingToken>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.token, "qr_offlineTest12345678ab")
        XCTAssertEqual(results.first?.retryCount, 0)
        XCTAssertEqual(results.first?.status, .pending)
    }

    @MainActor
    func testPendingTokenRetryIncrement() throws {
        let pending = PendingToken(token: "qr_retryTest12345678abcd")
        context.insert(pending)

        pending.retryCount += 1
        pending.lastRetryAt = Date()
        try context.save()

        let descriptor = FetchDescriptor<PendingToken>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.first?.retryCount, 1)
        XCTAssertNotNil(results.first?.lastRetryAt)
    }

    @MainActor
    func testPendingTokenQueueLimit() throws {
        // Insert 5 pending tokens (the max)
        for i in 0..<5 {
            let token = "qr_queueTest\(i)ABCDE12345678"
            let pending = PendingToken(token: token)
            context.insert(pending)
        }
        try context.save()

        let pendingRaw = PendingTokenStatus.pending.rawValue
        let descriptor = FetchDescriptor<PendingToken>(
            predicate: #Predicate { $0.statusRaw == pendingRaw }
        )
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 5)
    }
}

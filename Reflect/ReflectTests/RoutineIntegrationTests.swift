// ReflectTests/RoutineIntegrationTests.swift
import XCTest
import SwiftData
@testable import Reflect

final class RoutineIntegrationTests: XCTestCase {

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

    @MainActor
    func testFullScanToRoutineFlow() async throws {
        // 1. Parse QR URL
        let url = "https://link.reflectapp.com/t/qr_POcQ38aDUKrqeyFQJibNKK"
        let tokenResult = TokenResolutionService.parseScanResult(url)
        guard case .success(let token) = tokenResult else {
            XCTFail("Expected valid token")
            return
        }
        XCTAssertEqual(token, "qr_POcQ38aDUKrqeyFQJibNKK")

        // 2. Simulate API response (using stub)
        let apiResponse = TokenResolveResponse(
            status: "active",
            tokenType: "LP",
            version: "v1",
            product: TokenProductInfo(
                productId: "prod_abc123",
                name: "Chamomile Calm Blend",
                category: "Herbal Tea",
                description: "A soothing herbal tea blend.",
                batchId: "batch_2024Q1_042",
                verifiedAt: "2025-11-15T10:30:00Z"
            ),
            cacheTTL: 86400
        )

        // 3. Cache product
        let product = TokenResolutionService.createOrUpdateProduct(
            token: token,
            response: apiResponse,
            context: context
        )
        try context.save()
        XCTAssertEqual(product.name, "Chamomile Calm Blend")

        // 4. Add to routine
        let vm = RoutineViewModel()
        vm.setup(context: context)
        let entry = vm.addToRoutine(product: product, schedule: .daily)
        try context.save()

        XCTAssertTrue(entry.isActive)
        XCTAssertEqual(entry.schedule, .daily)

        // 5. Log adherence
        let log = vm.logEntry(entry)
        try context.save()

        XCTAssertFalse(log.skipped)

        // 6. Check adherence
        let adherence = vm.weeklyAdherence(for: entry)
        XCTAssertEqual(adherence.logged, 1)
        XCTAssertEqual(adherence.expected, 7)

        // 7. Verify cache lookup works
        let cached = try TokenResolutionService.findCachedProduct(token: token, context: context)
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.productId, "prod_abc123")
    }

    @MainActor
    func testOfflineQueueAndResolution() async throws {
        // 1. Parse valid URL
        let url = "https://link.reflectapp.com/t/qr_offlineTest12345678ab"
        let tokenResult = TokenResolutionService.parseScanResult(url)
        guard case .success(let token) = tokenResult else {
            XCTFail("Expected valid token")
            return
        }

        // 2. Queue for offline resolution
        try TokenResolutionService.addToPendingQueue(token: token, context: context)
        try context.save()

        // 3. Verify pending
        let pending = try TokenResolutionService.pendingTokens(context: context)
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.token, token)

        // 4. Simulate resolution
        let apiResponse = TokenResolveResponse(
            status: "active",
            tokenType: "LP",
            version: "v1",
            product: TokenProductInfo(
                productId: "prod_offline",
                name: "Offline Product",
                category: "Supplement",
                description: nil,
                batchId: nil,
                verifiedAt: "2025-12-01T00:00:00Z"
            ),
            cacheTTL: 86400
        )

        let product = TokenResolutionService.createOrUpdateProduct(
            token: token,
            response: apiResponse,
            context: context
        )
        TokenResolutionService.removePendingToken(pending.first!, context: context)
        try context.save()

        // 5. Verify product cached and queue empty
        XCTAssertEqual(product.name, "Offline Product")
        let remainingPending = try TokenResolutionService.pendingTokens(context: context)
        XCTAssertEqual(remainingPending.count, 0)
    }

    @MainActor
    func testRevocationDeactivatesRoutine() throws {
        // 1. Create verified product
        let product = VerifiedProduct(
            productId: "prod_revoke",
            token: "qr_revokeTest12345678abcd",
            name: "Revocable Product",
            category: "Test"
        )
        context.insert(product)

        // 2. Add to routine
        let entry = RoutineEntry(product: product, schedule: .daily)
        context.insert(entry)
        try context.save()
        XCTAssertTrue(entry.isActive)

        // 3. Simulate revocation
        product.status = .revoked
        entry.isActive = false
        try context.save()

        // 4. Verify
        XCTAssertEqual(product.status, .revoked)
        XCTAssertFalse(entry.isActive)
    }
}

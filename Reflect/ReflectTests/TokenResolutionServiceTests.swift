// ReflectTests/TokenResolutionServiceTests.swift
import XCTest
import SwiftData
@testable import Reflect

final class TokenResolutionServiceTests: XCTestCase {

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

    // MARK: - Scan Result from URL

    @MainActor
    func testScanResultFromInvalidURL() {
        let result = TokenResolutionService.parseScanResult("https://evil.com/t/qr_abc")
        if case .failure(let error) = result {
            XCTAssertEqual(error, .invalidDomain)
        } else {
            XCTFail("Expected failure")
        }
    }

    @MainActor
    func testScanResultFromValidURL() {
        let result = TokenResolutionService.parseScanResult(
            "https://link.reflectapp.com/t/qr_POcQ38aDUKrqeyFQJibNKK"
        )
        XCTAssertEqual(result, .success("qr_POcQ38aDUKrqeyFQJibNKK"))
    }

    // MARK: - Cache Lookup

    @MainActor
    func testFindCachedProduct() throws {
        let product = VerifiedProduct(
            productId: "prod_abc",
            token: "qr_POcQ38aDUKrqeyFQJibNKK",
            name: "Test",
            category: "Test"
        )
        context.insert(product)
        try context.save()

        let found = try TokenResolutionService.findCachedProduct(
            token: "qr_POcQ38aDUKrqeyFQJibNKK",
            context: context
        )
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.name, "Test")
    }

    @MainActor
    func testCachedProductNotFound() throws {
        let found = try TokenResolutionService.findCachedProduct(
            token: "qr_doesNotExist1234567890",
            context: context
        )
        XCTAssertNil(found)
    }

    // MARK: - Create/Update from API Response

    @MainActor
    func testCreateProductFromAPIResponse() throws {
        let response = TokenResolveResponse(
            status: "active",
            tokenType: "LP",
            version: "v1",
            product: TokenProductInfo(
                productId: "prod_xyz",
                name: "Daily Wellness Blend",
                category: "Supplement",
                description: "A daily herbal supplement blend.",
                batchId: "batch_001",
                verifiedAt: "2025-11-15T10:30:00Z"
            ),
            cacheTTL: 86400
        )

        let product = TokenResolutionService.createOrUpdateProduct(
            token: "qr_newProduct12345678abcd",
            response: response,
            context: context
        )
        try context.save()

        XCTAssertEqual(product.name, "Daily Wellness Blend")
        XCTAssertEqual(product.category, "Supplement")
        XCTAssertEqual(product.cacheTTL, 86400)

        let descriptor = FetchDescriptor<VerifiedProduct>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 1)
    }

    @MainActor
    func testUpdateExistingProductFromAPIResponse() throws {
        // Insert existing product
        let existing = VerifiedProduct(
            productId: "prod_xyz",
            token: "qr_existingProduct123456ab",
            name: "Old Name",
            category: "Old Category"
        )
        context.insert(existing)
        try context.save()

        let response = TokenResolveResponse(
            status: "active",
            tokenType: "LP",
            version: "v1",
            product: TokenProductInfo(
                productId: "prod_xyz",
                name: "New Name",
                category: "New Category",
                description: nil,
                batchId: nil,
                verifiedAt: "2025-11-15T10:30:00Z"
            ),
            cacheTTL: 43200
        )

        let product = TokenResolutionService.createOrUpdateProduct(
            token: "qr_existingProduct123456ab",
            response: response,
            context: context
        )
        try context.save()

        XCTAssertEqual(product.name, "New Name")
        XCTAssertEqual(product.cacheTTL, 43200)

        let descriptor = FetchDescriptor<VerifiedProduct>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 1, "Should update, not duplicate")
    }

    // MARK: - Pending Queue

    @MainActor
    func testAddToPendingQueue() throws {
        try TokenResolutionService.addToPendingQueue(
            token: "qr_pendingTest12345678abcd",
            context: context
        )

        let descriptor = FetchDescriptor<PendingToken>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.status, .pending)
    }

    @MainActor
    func testPendingQueueMaxFive() throws {
        for i in 0..<5 {
            try TokenResolutionService.addToPendingQueue(
                token: "qr_queue\(i)test1234567890ab",
                context: context
            )
        }

        XCTAssertThrowsError(
            try TokenResolutionService.addToPendingQueue(
                token: "qr_queue5test1234567890ab",
                context: context
            )
        ) { error in
            XCTAssertEqual(error as? TokenResolutionError, .pendingQueueFull)
        }
    }

    @MainActor
    func testNoDuplicatePendingTokens() throws {
        try TokenResolutionService.addToPendingQueue(
            token: "qr_duplicateTest123456abcd",
            context: context
        )
        try TokenResolutionService.addToPendingQueue(
            token: "qr_duplicateTest123456abcd",
            context: context
        )

        let descriptor = FetchDescriptor<PendingToken>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 1, "Should not create duplicate")
    }
}

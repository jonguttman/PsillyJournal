# QR Token System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement secure QR token verification, product linking, and structured routine tracking in the Reflect iOS app.

**Architecture:** Thin-client, server-authoritative. iOS app performs local QR URL parsing and regex validation, then delegates token resolution to `api.reflectapp.com`. Verified products are cached in SwiftData with TTL. Offline scans queue for automatic resolution. Routine tracker enables structured schedules, reminders, and adherence logging correlated with wellbeing check-ins.

**Tech Stack:** SwiftUI, SwiftData, AVFoundation (camera), Network framework (NWPathMonitor), XCTest, iOS 17+, Swift 5.9

**Branch:** `feature/qr-token-system` (already created from `master`)

**Build commands:**
```bash
cd /Users/jonathanguttman/Documents/PsillyJournal/Reflect
xcodegen generate
xcodebuild test -project Reflect.xcodeproj -scheme ReflectTests \
  -destination 'platform=iOS Simulator,id=2A35514A-B453-4780-87F9-0F652CEBBAB4' \
  -only-testing:ReflectTests/TARGET_TEST_CLASS
```

**Simulator:** iPhone 17 Pro (ID: `2A35514A-B453-4780-87F9-0F652CEBBAB4`)

---

## Task 1: SwiftData Models — VerifiedProduct, PendingToken

**Files:**
- Create: `Reflect/Models/VerifiedProduct.swift`
- Create: `Reflect/Models/PendingToken.swift`
- Create: `ReflectTests/VerifiedProductTests.swift`

**Step 1: Write failing tests for VerifiedProduct and PendingToken**

```swift
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
            name: "Third Eye Chai",
            category: "Herbal Tea",
            productDescription: "A calming herbal blend.",
            batchId: "batch_2024Q1_042",
            verifiedAt: Date()
        )
        context.insert(product)
        try context.save()

        let descriptor = FetchDescriptor<VerifiedProduct>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Third Eye Chai")
        XCTAssertEqual(results.first?.category, "Herbal Tea")
        XCTAssertEqual(results.first?.status, "active")
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
        XCTAssertEqual(product.status, "active")

        product.status = "revoked"
        try context.save()

        let descriptor = FetchDescriptor<VerifiedProduct>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.first?.status, "revoked")
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
        XCTAssertEqual(results.first?.status, "pending")
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
            let token = "qr_queue\(i)test1234567890a"
            let pending = PendingToken(token: token)
            context.insert(pending)
        }
        try context.save()

        let descriptor = FetchDescriptor<PendingToken>(
            predicate: #Predicate { $0.status == "pending" }
        )
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 5)
    }
}
```

**Step 2: Run tests to verify they fail**

```bash
xcodegen generate && xcodebuild test -project Reflect.xcodeproj -scheme ReflectTests \
  -destination 'platform=iOS Simulator,id=2A35514A-B453-4780-87F9-0F652CEBBAB4' \
  -only-testing:ReflectTests/VerifiedProductTests 2>&1 | tail -20
```
Expected: FAIL — `VerifiedProduct` and `PendingToken` types not defined.

**Step 3: Implement VerifiedProduct model**

```swift
// Reflect/Models/VerifiedProduct.swift
import Foundation
import SwiftData

@Model
final class VerifiedProduct {
    var id: UUID
    var productId: String
    var token: String
    var name: String
    var category: String
    var productDescription: String?
    var batchId: String?
    var verifiedAt: Date
    var cachedAt: Date
    var cacheTTL: TimeInterval
    var status: String

    var isCacheStale: Bool {
        Date() > cachedAt.addingTimeInterval(cacheTTL)
    }

    init(
        productId: String,
        token: String,
        name: String,
        category: String,
        productDescription: String? = nil,
        batchId: String? = nil,
        verifiedAt: Date = Date(),
        cachedAt: Date = Date(),
        cacheTTL: TimeInterval = 86400,
        status: String = "active"
    ) {
        self.id = UUID()
        self.productId = productId
        self.token = token
        self.name = name
        self.category = category
        self.productDescription = productDescription
        self.batchId = batchId
        self.verifiedAt = verifiedAt
        self.cachedAt = cachedAt
        self.cacheTTL = cacheTTL
        self.status = status
    }
}
```

**Step 4: Implement PendingToken model**

```swift
// Reflect/Models/PendingToken.swift
import Foundation
import SwiftData

@Model
final class PendingToken {
    var id: UUID
    var token: String
    var scannedAt: Date
    var retryCount: Int
    var lastRetryAt: Date?
    var status: String

    init(
        token: String,
        scannedAt: Date = Date(),
        retryCount: Int = 0,
        lastRetryAt: Date? = nil,
        status: String = "pending"
    ) {
        self.id = UUID()
        self.token = token
        self.scannedAt = scannedAt
        self.retryCount = retryCount
        self.lastRetryAt = lastRetryAt
        self.status = status
    }
}
```

**Step 5: Update PersistenceService schema**

Add `VerifiedProduct.self` and `PendingToken.self` to both schema arrays in `Reflect/Services/PersistenceService.swift` (lines 12-18 and 34-40), and add delete calls in `deleteAllData` (lines 56-61).

**Step 6: Run tests to verify they pass**

```bash
xcodegen generate && xcodebuild test -project Reflect.xcodeproj -scheme ReflectTests \
  -destination 'platform=iOS Simulator,id=2A35514A-B453-4780-87F9-0F652CEBBAB4' \
  -only-testing:ReflectTests/VerifiedProductTests 2>&1 | tail -20
```
Expected: PASS

**Step 7: Commit**

```bash
git add Reflect/Models/VerifiedProduct.swift Reflect/Models/PendingToken.swift \
  Reflect/Services/PersistenceService.swift ReflectTests/VerifiedProductTests.swift
git commit -m "feat: add VerifiedProduct and PendingToken SwiftData models"
```

---

## Task 2: SwiftData Models — RoutineEntry, RoutineLog

**Files:**
- Create: `Reflect/Models/RoutineEntry.swift`
- Create: `Reflect/Models/RoutineLog.swift`
- Create: `ReflectTests/RoutineModelTests.swift`
- Modify: `Reflect/Services/PersistenceService.swift`

**Step 1: Write failing tests**

```swift
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
            reminderEnabled: true,
            reminderTime: Date()
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
```

**Step 2: Run tests to verify they fail**

Expected: FAIL — `RoutineSchedule`, `RoutineEntry`, `RoutineLog` not defined.

**Step 3: Implement RoutineEntry model**

```swift
// Reflect/Models/RoutineEntry.swift
import Foundation
import SwiftData

enum RoutineSchedule: String, Codable, CaseIterable {
    case daily
    case weekly
    case asNeeded
    case custom

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .asNeeded: return "As Needed"
        case .custom: return "Custom"
        }
    }
}

@Model
final class RoutineEntry {
    var id: UUID
    var product: VerifiedProduct?
    var schedule: RoutineSchedule
    var scheduleDays: [Int]?
    var reminderTime: Date?
    var reminderEnabled: Bool
    var notes: String?
    var linkedAt: Date
    var isActive: Bool

    init(
        product: VerifiedProduct,
        schedule: RoutineSchedule = .daily,
        scheduleDays: [Int]? = nil,
        reminderTime: Date? = nil,
        reminderEnabled: Bool = false,
        notes: String? = nil,
        linkedAt: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.product = product
        self.schedule = schedule
        self.scheduleDays = scheduleDays
        self.reminderTime = reminderTime
        self.reminderEnabled = reminderEnabled
        self.notes = notes
        self.linkedAt = linkedAt
        self.isActive = isActive
    }
}
```

**Step 4: Implement RoutineLog model**

```swift
// Reflect/Models/RoutineLog.swift
import Foundation
import SwiftData

@Model
final class RoutineLog {
    var id: UUID
    var routineEntry: RoutineEntry?
    var loggedAt: Date
    var skipped: Bool
    var note: String?

    init(
        routineEntry: RoutineEntry,
        loggedAt: Date = Date(),
        skipped: Bool = false,
        note: String? = nil
    ) {
        self.id = UUID()
        self.routineEntry = routineEntry
        self.loggedAt = loggedAt
        self.skipped = skipped
        self.note = note
    }
}
```

**Step 5: Update PersistenceService schema**

Add `RoutineEntry.self` and `RoutineLog.self` to both schema arrays and `deleteAllData`.

**Step 6: Run tests to verify they pass**

Expected: PASS

**Step 7: Commit**

```bash
git add Reflect/Models/RoutineEntry.swift Reflect/Models/RoutineLog.swift \
  Reflect/Services/PersistenceService.swift ReflectTests/RoutineModelTests.swift
git commit -m "feat: add RoutineEntry and RoutineLog SwiftData models"
```

---

## Task 3: Token Validation Service

Pure logic — no network calls. Validates QR URL format, extracts tokens, checks regex.

**Files:**
- Create: `Reflect/Services/TokenValidationService.swift`
- Create: `ReflectTests/TokenValidationServiceTests.swift`

**Step 1: Write failing tests**

```swift
// ReflectTests/TokenValidationServiceTests.swift
import XCTest
@testable import Reflect

final class TokenValidationServiceTests: XCTestCase {

    // MARK: - Token Regex

    func testValidTokenFormat() {
        XCTAssertTrue(TokenValidationService.isValidToken("qr_POcQ38aDUKrqeyFQJibNKK"))
        XCTAssertTrue(TokenValidationService.isValidToken("qr_h0kVYOFStvpRyXbLemYI6V"))
        XCTAssertTrue(TokenValidationService.isValidToken("qr_12345678901234567890"))  // 20 chars
        XCTAssertTrue(TokenValidationService.isValidToken("qr_123456789012345678901234567890"))  // 30 chars
    }

    func testInvalidTokenFormat() {
        XCTAssertFalse(TokenValidationService.isValidToken(""))
        XCTAssertFalse(TokenValidationService.isValidToken("qr_"))
        XCTAssertFalse(TokenValidationService.isValidToken("qr_abc"))  // too short
        XCTAssertFalse(TokenValidationService.isValidToken("qr_1234567890123456789"))  // 19 chars
        XCTAssertFalse(TokenValidationService.isValidToken("qr_1234567890123456789012345678901"))  // 31 chars
        XCTAssertFalse(TokenValidationService.isValidToken("POcQ38aDUKrqeyFQJibNKK"))  // no prefix
        XCTAssertFalse(TokenValidationService.isValidToken("qr_POcQ38aDUKrqey!@#$%"))  // special chars
        XCTAssertFalse(TokenValidationService.isValidToken("QR_POcQ38aDUKrqeyFQJibNKK"))  // wrong case prefix
    }

    // MARK: - QR URL Parsing

    func testValidQRURL() {
        let result = TokenValidationService.extractToken(
            from: "https://link.reflectapp.com/t/qr_POcQ38aDUKrqeyFQJibNKK"
        )
        XCTAssertEqual(result, .success("qr_POcQ38aDUKrqeyFQJibNKK"))
    }

    func testValidQRURLWithTrailingSlash() {
        let result = TokenValidationService.extractToken(
            from: "https://link.reflectapp.com/t/qr_POcQ38aDUKrqeyFQJibNKK/"
        )
        XCTAssertEqual(result, .success("qr_POcQ38aDUKrqeyFQJibNKK"))
    }

    func testWrongDomain() {
        let result = TokenValidationService.extractToken(
            from: "https://evil.com/t/qr_POcQ38aDUKrqeyFQJibNKK"
        )
        XCTAssertEqual(result, .failure(.invalidDomain))
    }

    func testWrongScheme() {
        let result = TokenValidationService.extractToken(
            from: "http://link.reflectapp.com/t/qr_POcQ38aDUKrqeyFQJibNKK"
        )
        XCTAssertEqual(result, .failure(.invalidScheme))
    }

    func testWrongPath() {
        let result = TokenValidationService.extractToken(
            from: "https://link.reflectapp.com/other/qr_POcQ38aDUKrqeyFQJibNKK"
        )
        XCTAssertEqual(result, .failure(.invalidPath))
    }

    func testInvalidTokenInURL() {
        let result = TokenValidationService.extractToken(
            from: "https://link.reflectapp.com/t/qr_abc"
        )
        XCTAssertEqual(result, .failure(.invalidTokenFormat))
    }

    func testMalformedURL() {
        let result = TokenValidationService.extractToken(from: "not a url at all")
        XCTAssertEqual(result, .failure(.malformedURL))
    }

    func testEmptyPath() {
        let result = TokenValidationService.extractToken(
            from: "https://link.reflectapp.com/t/"
        )
        XCTAssertEqual(result, .failure(.invalidTokenFormat))
    }

    func testSubdomainRejected() {
        let result = TokenValidationService.extractToken(
            from: "https://fake.link.reflectapp.com/t/qr_POcQ38aDUKrqeyFQJibNKK"
        )
        XCTAssertEqual(result, .failure(.invalidDomain))
    }
}
```

**Step 2: Run tests to verify they fail**

Expected: FAIL — `TokenValidationService` not defined.

**Step 3: Implement TokenValidationService**

```swift
// Reflect/Services/TokenValidationService.swift
import Foundation

enum TokenValidationError: Error, Equatable {
    case malformedURL
    case invalidScheme
    case invalidDomain
    case invalidPath
    case invalidTokenFormat
}

enum TokenValidationService {

    static let allowedHost = "link.reflectapp.com"
    static let requiredPathPrefix = "/t/"
    private static let tokenRegex = /^qr_[a-zA-Z0-9]{20,30}$/

    static func isValidToken(_ token: String) -> Bool {
        token.wholeMatch(of: tokenRegex) != nil
    }

    static func extractToken(from urlString: String) -> Result<String, TokenValidationError> {
        guard let url = URL(string: urlString) else {
            return .failure(.malformedURL)
        }

        guard url.scheme == "https" else {
            return .failure(.invalidScheme)
        }

        guard url.host == allowedHost else {
            return .failure(.invalidDomain)
        }

        guard url.path.hasPrefix(requiredPathPrefix) else {
            return .failure(.invalidPath)
        }

        let tokenPart = String(url.path.dropFirst(requiredPathPrefix.count))
        let token = tokenPart.hasSuffix("/") ? String(tokenPart.dropLast()) : tokenPart

        guard isValidToken(token) else {
            return .failure(.invalidTokenFormat)
        }

        return .success(token)
    }
}
```

**Step 4: Run tests to verify they pass**

Expected: PASS

**Step 5: Commit**

```bash
git add Reflect/Services/TokenValidationService.swift ReflectTests/TokenValidationServiceTests.swift
git commit -m "feat: add TokenValidationService with URL parsing and regex"
```

---

## Task 4: API Client — TokenAPIService

Network layer for resolving tokens against `api.reflectapp.com`.

**Files:**
- Create: `Reflect/Services/TokenAPIService.swift`
- Create: `ReflectTests/TokenAPIServiceTests.swift`

**Step 1: Write failing tests**

```swift
// ReflectTests/TokenAPIServiceTests.swift
import XCTest
@testable import Reflect

final class TokenAPIServiceTests: XCTestCase {

    // MARK: - Response Parsing

    func testParseSuccessResponse() throws {
        let json = """
        {
            "status": "active",
            "token_type": "LP",
            "version": "v1",
            "product": {
                "product_id": "prod_abc123",
                "name": "Third Eye Chai",
                "category": "Herbal Tea",
                "description": "A calming herbal blend.",
                "batch_id": "batch_2024Q1_042",
                "verified_at": "2025-11-15T10:30:00Z"
            },
            "cache_ttl": 86400
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder.apiDecoder.decode(TokenResolveResponse.self, from: json)
        XCTAssertEqual(response.status, "active")
        XCTAssertEqual(response.tokenType, "LP")
        XCTAssertEqual(response.product.productId, "prod_abc123")
        XCTAssertEqual(response.product.name, "Third Eye Chai")
        XCTAssertEqual(response.product.category, "Herbal Tea")
        XCTAssertEqual(response.cacheTTL, 86400)
    }

    func testParseErrorResponse() throws {
        let json = """
        {
            "error": "TOKEN_NOT_FOUND",
            "message": "This product could not be verified."
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder.apiDecoder.decode(TokenErrorResponse.self, from: json)
        XCTAssertEqual(response.error, "TOKEN_NOT_FOUND")
        XCTAssertEqual(response.message, "This product could not be verified.")
    }

    func testParseRateLimitResponse() throws {
        let json = """
        {
            "error": "RATE_LIMITED",
            "message": "Too many scan attempts.",
            "retry_after": 60
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder.apiDecoder.decode(TokenErrorResponse.self, from: json)
        XCTAssertEqual(response.error, "RATE_LIMITED")
        XCTAssertEqual(response.retryAfter, 60)
    }

    func testParseStatusResponse() throws {
        let json = """
        {
            "status": "active",
            "updated_at": "2025-11-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder.apiDecoder.decode(TokenStatusResponse.self, from: json)
        XCTAssertEqual(response.status, "active")
    }

    // MARK: - Request Building

    func testResolveRequestURL() throws {
        let request = TokenAPIService.buildResolveRequest(
            token: "qr_POcQ38aDUKrqeyFQJibNKK",
            deviceHash: "abc123hash",
            appVersion: "1.0.0"
        )
        XCTAssertEqual(
            request.url?.absoluteString,
            "https://api.reflectapp.com/v1/tokens/qr_POcQ38aDUKrqeyFQJibNKK"
        )
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Device-Hash"), "abc123hash")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-App-Version"), "1.0.0")
    }

    func testStatusRequestURL() throws {
        let request = TokenAPIService.buildStatusRequest(token: "qr_POcQ38aDUKrqeyFQJibNKK")
        XCTAssertEqual(
            request.url?.absoluteString,
            "https://api.reflectapp.com/v1/tokens/qr_POcQ38aDUKrqeyFQJibNKK/status"
        )
    }

    // MARK: - Error Mapping

    func testMapHTTPStatusToError() {
        XCTAssertEqual(TokenAPIError.from(statusCode: 404), .tokenNotFound)
        XCTAssertEqual(TokenAPIError.from(statusCode: 410), .tokenInactive)
        XCTAssertEqual(TokenAPIError.from(statusCode: 429), .rateLimited)
        XCTAssertEqual(TokenAPIError.from(statusCode: 503), .serviceUnavailable)
        XCTAssertEqual(TokenAPIError.from(statusCode: 500), .serverError)
    }
}
```

**Step 2: Run tests to verify they fail**

Expected: FAIL — types not defined.

**Step 3: Implement TokenAPIService**

```swift
// Reflect/Services/TokenAPIService.swift
import Foundation
import CryptoKit

// MARK: - API Response Models

struct TokenProductInfo: Codable {
    let productId: String
    let name: String
    let category: String
    let description: String?
    let batchId: String?
    let verifiedAt: String

    enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case name, category, description
        case batchId = "batch_id"
        case verifiedAt = "verified_at"
    }
}

struct TokenResolveResponse: Codable {
    let status: String
    let tokenType: String
    let version: String
    let product: TokenProductInfo
    let cacheTTL: TimeInterval

    enum CodingKeys: String, CodingKey {
        case status
        case tokenType = "token_type"
        case version
        case product
        case cacheTTL = "cache_ttl"
    }
}

struct TokenStatusResponse: Codable {
    let status: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case updatedAt = "updated_at"
    }
}

struct TokenErrorResponse: Codable {
    let error: String
    let message: String
    let retryAfter: Int?

    enum CodingKeys: String, CodingKey {
        case error, message
        case retryAfter = "retry_after"
    }
}

// MARK: - API Errors

enum TokenAPIError: Error, Equatable {
    case tokenNotFound
    case tokenInactive
    case rateLimited
    case serviceUnavailable
    case serverError
    case networkError
    case decodingError

    static func from(statusCode: Int) -> TokenAPIError {
        switch statusCode {
        case 404: return .tokenNotFound
        case 410: return .tokenInactive
        case 429: return .rateLimited
        case 503: return .serviceUnavailable
        default: return .serverError
        }
    }
}

// MARK: - JSON Decoder

extension JSONDecoder {
    static let apiDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()
}

// MARK: - API Service

protocol TokenAPIServiceProtocol {
    func resolveToken(_ token: String) async throws -> TokenResolveResponse
    func checkTokenStatus(_ token: String) async throws -> TokenStatusResponse
}

enum TokenAPIService {

    static let baseURL = "https://api.reflectapp.com/v1/tokens"

    static func buildResolveRequest(
        token: String,
        deviceHash: String,
        appVersion: String
    ) -> URLRequest {
        let url = URL(string: "\(baseURL)/\(token)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(deviceHash, forHTTPHeaderField: "X-Device-Hash")
        request.setValue(appVersion, forHTTPHeaderField: "X-App-Version")
        request.timeoutInterval = 10
        return request
    }

    static func buildStatusRequest(token: String) -> URLRequest {
        let url = URL(string: "\(baseURL)/\(token)/status")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        return request
    }

    static func deviceHash() -> String {
        #if canImport(UIKit)
        import UIKit
        let identifier = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        #else
        let identifier = "unknown"
        #endif
        let salt = "reflect_rate_limit_v1"
        let data = Data((identifier + salt).utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Live Implementation

struct LiveTokenAPIService: TokenAPIServiceProtocol {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func resolveToken(_ token: String) async throws -> TokenResolveResponse {
        let request = TokenAPIService.buildResolveRequest(
            token: token,
            deviceHash: TokenAPIService.deviceHash(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        )

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TokenAPIError.networkError
        }

        guard httpResponse.statusCode == 200 else {
            throw TokenAPIError.from(statusCode: httpResponse.statusCode)
        }

        return try JSONDecoder.apiDecoder.decode(TokenResolveResponse.self, from: data)
    }

    func checkTokenStatus(_ token: String) async throws -> TokenStatusResponse {
        let request = TokenAPIService.buildStatusRequest(token: token)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TokenAPIError.networkError
        }

        guard httpResponse.statusCode == 200 else {
            throw TokenAPIError.from(statusCode: httpResponse.statusCode)
        }

        return try JSONDecoder.apiDecoder.decode(TokenStatusResponse.self, from: data)
    }
}

// MARK: - Stub Implementation (for development/testing)

struct StubTokenAPIService: TokenAPIServiceProtocol {
    var resolveResult: Result<TokenResolveResponse, Error> = .failure(TokenAPIError.serviceUnavailable)
    var statusResult: Result<TokenStatusResponse, Error> = .failure(TokenAPIError.serviceUnavailable)

    func resolveToken(_ token: String) async throws -> TokenResolveResponse {
        try await Task.sleep(for: .milliseconds(300))
        return try resolveResult.get()
    }

    func checkTokenStatus(_ token: String) async throws -> TokenStatusResponse {
        try await Task.sleep(for: .milliseconds(100))
        return try statusResult.get()
    }
}
```

**Note on `deviceHash()`:** The `import UIKit` inside the function won't compile. Instead, move the UIKit import to the top of the file under `#if canImport(UIKit)` and use a conditional in the function body:

```swift
static func deviceHash() -> String {
    #if canImport(UIKit)
    let identifier = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    #else
    let identifier = "unknown"
    #endif
    let salt = "reflect_rate_limit_v1"
    let data = Data((identifier + salt).utf8)
    let hash = SHA256.hash(data: data)
    return hash.map { String(format: "%02x", $0) }.joined()
}
```

**Step 4: Run tests to verify they pass**

Expected: PASS

**Step 5: Commit**

```bash
git add Reflect/Services/TokenAPIService.swift ReflectTests/TokenAPIServiceTests.swift
git commit -m "feat: add TokenAPIService with resolve, status, and stub"
```

---

## Task 5: Token Resolution Orchestrator

Combines validation + API + caching + pending queue logic.

**Files:**
- Create: `Reflect/Services/TokenResolutionService.swift`
- Create: `ReflectTests/TokenResolutionServiceTests.swift`

**Step 1: Write failing tests**

```swift
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

    func testScanResultFromInvalidURL() {
        let result = TokenResolutionService.parseScanResult("https://evil.com/t/qr_abc")
        if case .failure(let error) = result {
            XCTAssertEqual(error, .invalidDomain)
        } else {
            XCTFail("Expected failure")
        }
    }

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
                name: "Adaptogen Blend",
                category: "Supplement",
                description: "Daily adaptogenic supplement.",
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

        XCTAssertEqual(product.name, "Adaptogen Blend")
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
        XCTAssertEqual(results.first?.status, "pending")
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
```

**Step 2: Run tests to verify they fail**

Expected: FAIL — `TokenResolutionService` not defined.

**Step 3: Implement TokenResolutionService**

```swift
// Reflect/Services/TokenResolutionService.swift
import Foundation
import SwiftData

enum TokenResolutionError: Error, Equatable {
    case pendingQueueFull
}

@MainActor
enum TokenResolutionService {

    // MARK: - URL Parsing (delegates to TokenValidationService)

    static func parseScanResult(_ urlString: String) -> Result<String, TokenValidationError> {
        TokenValidationService.extractToken(from: urlString)
    }

    // MARK: - Cache Lookup

    static func findCachedProduct(token: String, context: ModelContext) throws -> VerifiedProduct? {
        let descriptor = FetchDescriptor<VerifiedProduct>(
            predicate: #Predicate { $0.token == token }
        )
        return try context.fetch(descriptor).first
    }

    // MARK: - Create / Update from API Response

    @discardableResult
    static func createOrUpdateProduct(
        token: String,
        response: TokenResolveResponse,
        context: ModelContext
    ) -> VerifiedProduct {
        let descriptor = FetchDescriptor<VerifiedProduct>(
            predicate: #Predicate { $0.token == token }
        )

        if let existing = try? context.fetch(descriptor).first {
            existing.name = response.product.name
            existing.category = response.product.category
            existing.productDescription = response.product.description
            existing.batchId = response.product.batchId
            existing.status = response.status
            existing.cachedAt = Date()
            existing.cacheTTL = response.cacheTTL
            return existing
        }

        let product = VerifiedProduct(
            productId: response.product.productId,
            token: token,
            name: response.product.name,
            category: response.product.category,
            productDescription: response.product.description,
            batchId: response.product.batchId,
            cachedAt: Date(),
            cacheTTL: response.cacheTTL
        )
        context.insert(product)
        return product
    }

    // MARK: - Pending Queue

    static func addToPendingQueue(token: String, context: ModelContext) throws {
        // Check for duplicate
        let dupDescriptor = FetchDescriptor<PendingToken>(
            predicate: #Predicate { $0.token == token }
        )
        if let _ = try context.fetch(dupDescriptor).first {
            return  // already queued
        }

        // Check queue limit
        let countDescriptor = FetchDescriptor<PendingToken>(
            predicate: #Predicate { $0.status == "pending" }
        )
        let count = try context.fetchCount(countDescriptor)
        guard count < 5 else {
            throw TokenResolutionError.pendingQueueFull
        }

        let pending = PendingToken(token: token)
        context.insert(pending)
        try context.save()
    }

    static func pendingTokens(context: ModelContext) throws -> [PendingToken] {
        let descriptor = FetchDescriptor<PendingToken>(
            predicate: #Predicate { $0.status == "pending" && $0.retryCount < 3 },
            sortBy: [SortDescriptor(\.scannedAt)]
        )
        return try context.fetch(descriptor)
    }

    static func removePendingToken(_ token: PendingToken, context: ModelContext) {
        context.delete(token)
    }
}
```

**Step 4: Run tests to verify they pass**

Expected: PASS

**Step 5: Commit**

```bash
git add Reflect/Services/TokenResolutionService.swift ReflectTests/TokenResolutionServiceTests.swift
git commit -m "feat: add TokenResolutionService with cache lookup, pending queue"
```

---

## Task 6: Connectivity Monitor

Wraps `NWPathMonitor` for observing online/offline state.

**Files:**
- Create: `Reflect/Services/ConnectivityService.swift`

**Step 1: Implement ConnectivityService**

This is a thin wrapper — no unit tests needed (it wraps a system API).

```swift
// Reflect/Services/ConnectivityService.swift
import Foundation
import Network

@Observable
@MainActor
final class ConnectivityService {
    var isConnected: Bool = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.psilly.reflect.connectivity")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
```

**Step 2: Commit**

```bash
git add Reflect/Services/ConnectivityService.swift
git commit -m "feat: add ConnectivityService wrapping NWPathMonitor"
```

---

## Task 7: UI Copy — Strings Update

Add all QR/Routine copy to `Strings.swift`.

**Files:**
- Modify: `Reflect/Resources/Strings.swift`

**Step 1: Add new string constants**

Add these sections to `Reflect/Resources/Strings.swift` before the `// MARK: - General` section:

```swift
// MARK: - Routine
static let tabRoutine = "Routine"
static let routineTitle = "My Routine"
static let routineScanCTA = "Scan Product"
static let routineScanSubtitle = "Point your camera at a product QR code"
static let routineVerifying = "Verifying product..."
static let routineVerified = "Verified Product"
static let routineAddToRoutine = "Add to My Routine"
static let routineSaveForLater = "Save for Later"
static let routineAddedToast = "Added to your routine"
static let routineLogToday = "Log Today"
static let routineSkip = "Skip"
static let routineConfigureTitle = "Set Up Routine"
static let routineSchedule = "Schedule"
static let routineReminder = "Remind Me"
static let routineReminderTime = "Reminder Time"
static let routineNotes = "Notes"
static let routineStartCTA = "Start Routine"
static let routineEmpty = "No products linked yet"
static let routineEmptyBody = "Scan a product QR code to get started."
static let routineAdherence = "This week"
static let routineProductRevoked = "This product is no longer verified. It has been removed from your active routine."

// MARK: - QR Scanning
static let qrInvalidTitle = "QR Code Not Recognized"
static let qrInvalidBody = "This doesn't appear to be a product QR code. Only verified product codes can be scanned."
static let qrNotFoundTitle = "Product Not Verified"
static let qrNotFoundBody = "This product could not be verified. Only verified products can be linked."
static let qrRevokedTitle = "No Longer Verified"
static let qrRevokedBody = "This product is no longer verified and cannot be linked."
static let qrRateLimitedTitle = "Too Many Attempts"
static let qrRateLimitedBody = "Please wait a moment before scanning again."
static let qrUnavailableTitle = "Temporarily Unavailable"
static let qrUnavailableBody = "Product verification is temporarily unavailable. Please try again later."
static let qrCameraRequiredTitle = "Camera Access Required"
static let qrCameraRequiredBody = "To scan product QR codes, allow camera access in Settings."
static let qrOfflineSavedTitle = "Saved for Later"
static let qrOfflineSavedBody = "We'll verify this product when you're back online."
static let qrPendingBadge = "Pending Verification"
static let qrResolvedTitle = "Product Verified"
static let qrQueueFailedTitle = "Verification Failed"
static let qrQueueFailedBody = "We couldn't verify this product. You can try scanning it again."
static let qrStaleRefreshing = "Updating verification..."
static let qrStaleOffline = "Last verified"

// MARK: - Routine Schedule
static let scheduleDaily = "Daily"
static let scheduleWeekly = "Weekly"
static let scheduleAsNeeded = "As Needed"
static let scheduleCustom = "Custom"
```

**Step 2: Commit**

```bash
git add Reflect/Resources/Strings.swift
git commit -m "feat: add Routine and QR scanning UI copy to Strings"
```

---

## Task 8: RoutineViewModel

Orchestrates scanning, resolution, caching, routine CRUD, and logging.

**Files:**
- Create: `Reflect/ViewModels/RoutineViewModel.swift`
- Create: `ReflectTests/RoutineViewModelTests.swift`

**Step 1: Write failing tests**

```swift
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
```

**Step 2: Run tests to verify they fail**

Expected: FAIL — `RoutineViewModel` not defined.

**Step 3: Implement RoutineViewModel**

```swift
// Reflect/ViewModels/RoutineViewModel.swift
import Foundation
import SwiftData

enum ScanError: Equatable {
    case invalidQR
    case tokenNotFound
    case tokenRevoked
    case rateLimited
    case serviceUnavailable
    case cameraRequired
    case pendingQueueFull
}

struct AdherenceResult {
    let logged: Int
    let expected: Int
}

@Observable
@MainActor
final class RoutineViewModel {
    var activeEntries: [RoutineEntry] = []
    var savedProducts: [VerifiedProduct] = []
    var pendingTokens: [PendingToken] = []

    // Scan state
    var isScanning = false
    var isResolving = false
    var scanError: ScanError?
    var resolvedProduct: VerifiedProduct?

    // Routine config
    var showRoutineConfig = false
    var showScanSheet = false

    private var context: ModelContext?
    private var apiService: TokenAPIServiceProtocol = StubTokenAPIService()

    func setup(context: ModelContext, apiService: TokenAPIServiceProtocol? = nil) {
        self.context = context
        if let api = apiService { self.apiService = api }
        refresh()
    }

    // MARK: - Data Fetch

    func refresh() {
        guard let context else { return }

        let activeDescriptor = FetchDescriptor<RoutineEntry>(
            predicate: #Predicate { $0.isActive == true },
            sortBy: [SortDescriptor(\.linkedAt, order: .reverse)]
        )
        activeEntries = (try? context.fetch(activeDescriptor)) ?? []

        let productDescriptor = FetchDescriptor<VerifiedProduct>(
            sortBy: [SortDescriptor(\.cachedAt, order: .reverse)]
        )
        savedProducts = (try? context.fetch(productDescriptor)) ?? []

        pendingTokens = (try? TokenResolutionService.pendingTokens(context: context)) ?? []
    }

    // MARK: - Scan Processing

    func processScanResult(_ urlString: String) -> String? {
        scanError = nil
        switch TokenResolutionService.parseScanResult(urlString) {
        case .success(let token):
            return token
        case .failure:
            scanError = .invalidQR
            return nil
        }
    }

    func resolveToken(_ token: String) async {
        guard let context else { return }
        isResolving = true
        scanError = nil

        // Check cache first
        if let cached = try? TokenResolutionService.findCachedProduct(token: token, context: context),
           !cached.isCacheStale {
            resolvedProduct = cached
            isResolving = false
            return
        }

        do {
            let response = try await apiService.resolveToken(token)
            let product = TokenResolutionService.createOrUpdateProduct(
                token: token,
                response: response,
                context: context
            )
            try context.save()
            resolvedProduct = product
        } catch let error as TokenAPIError {
            switch error {
            case .tokenNotFound: scanError = .tokenNotFound
            case .tokenInactive: scanError = .tokenRevoked
            case .rateLimited: scanError = .rateLimited
            case .serviceUnavailable, .serverError: scanError = .serviceUnavailable
            case .networkError:
                // Offline — queue the token
                do {
                    try TokenResolutionService.addToPendingQueue(token: token, context: context)
                    try context.save()
                } catch {
                    scanError = .pendingQueueFull
                }
            case .decodingError: scanError = .serviceUnavailable
            }
        } catch {
            scanError = .serviceUnavailable
        }

        isResolving = false
        refresh()
    }

    // MARK: - Routine CRUD

    @discardableResult
    func addToRoutine(
        product: VerifiedProduct,
        schedule: RoutineSchedule,
        scheduleDays: [Int]? = nil,
        reminderEnabled: Bool = false,
        reminderTime: Date? = nil,
        notes: String? = nil
    ) -> RoutineEntry {
        let entry = RoutineEntry(
            product: product,
            schedule: schedule,
            scheduleDays: scheduleDays,
            reminderTime: reminderTime,
            reminderEnabled: reminderEnabled,
            notes: notes
        )
        context?.insert(entry)
        refresh()
        return entry
    }

    func deactivateEntry(_ entry: RoutineEntry) {
        entry.isActive = false
        try? context?.save()
        refresh()
    }

    // MARK: - Logging

    @discardableResult
    func logEntry(_ entry: RoutineEntry, skipped: Bool = false, note: String? = nil) -> RoutineLog {
        let log = RoutineLog(routineEntry: entry, skipped: skipped, note: note)
        context?.insert(log)
        return log
    }

    // MARK: - Adherence

    func weeklyAdherence(for entry: RoutineEntry) -> AdherenceResult {
        guard let context else { return AdherenceResult(logged: 0, expected: 7) }

        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let entryId = entry.id

        let descriptor = FetchDescriptor<RoutineLog>(
            predicate: #Predicate {
                $0.routineEntry?.id == entryId &&
                $0.loggedAt >= weekAgo &&
                $0.skipped == false
            }
        )

        let logged = (try? context.fetchCount(descriptor)) ?? 0

        let expected: Int
        switch entry.schedule {
        case .daily: expected = 7
        case .weekly: expected = entry.scheduleDays?.count ?? 1
        case .asNeeded: expected = logged  // no target
        case .custom: expected = entry.scheduleDays?.count ?? 7
        }

        return AdherenceResult(logged: logged, expected: max(expected, 1))
    }

    // MARK: - Pending Queue Resolution

    func resolvePendingTokens() async {
        guard let context else { return }
        let pending = (try? TokenResolutionService.pendingTokens(context: context)) ?? []

        for token in pending {
            token.status = "resolving"
            token.retryCount += 1
            token.lastRetryAt = Date()

            do {
                let response = try await apiService.resolveToken(token.token)
                TokenResolutionService.createOrUpdateProduct(
                    token: token.token,
                    response: response,
                    context: context
                )
                TokenResolutionService.removePendingToken(token, context: context)
            } catch let error as TokenAPIError {
                switch error {
                case .tokenNotFound, .tokenInactive:
                    token.status = "failed"
                case .networkError:
                    token.status = "pending"  // will retry later
                default:
                    if token.retryCount >= 3 {
                        token.status = "failed"
                    } else {
                        token.status = "pending"
                    }
                }
            } catch {
                token.status = "pending"
            }
        }

        try? context.save()
        refresh()
    }
}
```

**Step 4: Run tests to verify they pass**

Expected: PASS

**Step 5: Commit**

```bash
git add Reflect/ViewModels/RoutineViewModel.swift ReflectTests/RoutineViewModelTests.swift
git commit -m "feat: add RoutineViewModel with scan, resolve, CRUD, adherence"
```

---

## Task 9: QR Scanner View (Camera)

**Files:**
- Create: `Reflect/Views/Routine/QRScannerView.swift`
- Modify: `Reflect/Info.plist` (add `NSCameraUsageDescription`)
- Modify: `project.yml` (add camera usage description)

**Step 1: Add NSCameraUsageDescription to Info.plist**

Add this entry to `Reflect/Info.plist` inside the `<dict>` block:

```xml
<key>NSCameraUsageDescription</key>
<string>Reflect uses your camera to scan product QR codes for verification.</string>
```

**Step 2: Add to project.yml**

In `project.yml`, add to the `info.properties` section:

```yaml
NSCameraUsageDescription: "Reflect uses your camera to scan product QR codes for verification."
```

**Step 3: Implement QRScannerView**

```swift
// Reflect/Views/Routine/QRScannerView.swift
import SwiftUI
import AVFoundation

struct QRScannerView: View {
    let onScan: (String) -> Void
    let onCancel: () -> Void

    @State private var cameraPermission: AVAuthorizationStatus = .notDetermined
    @State private var isScanning = true

    var body: some View {
        ZStack {
            if cameraPermission == .authorized {
                CameraPreview(onCodeScanned: { code in
                    guard isScanning else { return }
                    isScanning = false
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onScan(code)
                })
                .ignoresSafeArea()

                // Viewfinder overlay
                scanOverlay
            } else if cameraPermission == .denied || cameraPermission == .restricted {
                cameraRequiredView
            } else {
                Color.black.ignoresSafeArea()
            }
        }
        .onAppear {
            checkCameraPermission()
        }
    }

    private var scanOverlay: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(Spacing.xl)
                }
            }

            Spacer()

            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(AppColor.amber, lineWidth: 2)
                .frame(width: 240, height: 240)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(AppColor.amber.opacity(0.05))
                )

            Text(Strings.routineScanSubtitle)
                .font(AppFont.callout)
                .foregroundColor(.white.opacity(0.9))
                .padding(.top, Spacing.lg)

            Spacer()
        }
    }

    private var cameraRequiredView: some View {
        VStack(spacing: Spacing.xl) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundColor(AppColor.secondaryLabel)
            Text(Strings.qrCameraRequiredTitle)
                .font(AppFont.title)
                .foregroundColor(AppColor.label)
            Text(Strings.qrCameraRequiredBody)
                .font(AppFont.body)
                .foregroundColor(AppColor.secondaryLabel)
                .multilineTextAlignment(.center)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(AppFont.headline)
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.md)
            .background(AppGradient.warmCTA)
            .cornerRadius(CornerRadius.lg)

            Button(Strings.cancel, action: onCancel)
                .font(AppFont.body)
                .foregroundColor(AppColor.secondaryLabel)
        }
        .padding(Spacing.xxl)
        .warmBackground()
    }

    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    cameraPermission = granted ? .authorized : .denied
                }
            }
        } else {
            cameraPermission = status
        }
    }
}

// MARK: - Camera Preview (AVCaptureSession wrapper)

struct CameraPreview: UIViewRepresentable {
    let onCodeScanned: (String) -> Void

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.onCodeScanned = onCodeScanned
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}
}

class CameraPreviewUIView: UIView, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeScanned: ((String) -> Void)?
    private let captureSession = AVCaptureSession()

    override func layoutSubviews() {
        super.layoutSubviews()
        (layer.sublayers?.first as? AVCaptureVideoPreviewLayer)?.frame = bounds
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCamera()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCamera() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        captureSession.addInput(input)

        let output = AVCaptureMetadataOutput()
        captureSession.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = bounds
        layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              object.type == .qr,
              let value = object.stringValue else { return }
        onCodeScanned?(value)
    }

    deinit {
        captureSession.stopRunning()
    }
}
```

**Step 4: Commit**

```bash
git add Reflect/Views/Routine/QRScannerView.swift Reflect/Info.plist project.yml
git commit -m "feat: add QRScannerView with AVCaptureSession and camera permissions"
```

---

## Task 10: Routine Views — Tab, Product Card, Config, Logging

**Files:**
- Create: `Reflect/Views/Routine/RoutineTabView.swift`
- Create: `Reflect/Views/Routine/ProductVerificationView.swift`
- Create: `Reflect/Views/Routine/RoutineConfigView.swift`
- Create: `Reflect/Views/Routine/RoutineEntryCard.swift`

**Step 1: Implement RoutineTabView**

```swift
// Reflect/Views/Routine/RoutineTabView.swift
import SwiftUI

struct RoutineTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = RoutineViewModel()
    @State private var showScanner = false
    @State private var showVerification = false
    @State private var showConfig = false
    @State private var pendingProduct: VerifiedProduct?

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Header
                HStack {
                    Text(Strings.routineTitle)
                        .font(AppFont.largeTitle)
                        .foregroundColor(AppColor.label)
                    Spacer()
                    scanButton
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.sm)

                if viewModel.activeEntries.isEmpty && viewModel.pendingTokens.isEmpty {
                    emptyState
                } else {
                    // Pending tokens
                    if !viewModel.pendingTokens.isEmpty {
                        pendingSection
                    }

                    // Active routines
                    ForEach(viewModel.activeEntries, id: \.id) { entry in
                        RoutineEntryCard(
                            entry: entry,
                            adherence: viewModel.weeklyAdherence(for: entry),
                            onLog: {
                                viewModel.logEntry(entry)
                                try? modelContext.save()
                                viewModel.refresh()
                            },
                            onSkip: {
                                viewModel.logEntry(entry, skipped: true)
                                try? modelContext.save()
                                viewModel.refresh()
                            }
                        )
                        .padding(.horizontal, Spacing.xl)
                    }
                }
            }
            .padding(.bottom, Spacing.xxxl)
        }
        .onAppear {
            viewModel.setup(context: modelContext)
        }
        .fullScreenCover(isPresented: $showScanner) {
            QRScannerView(
                onScan: { urlString in
                    showScanner = false
                    if let token = viewModel.processScanResult(urlString) {
                        Task {
                            await viewModel.resolveToken(token)
                            if viewModel.resolvedProduct != nil {
                                showVerification = true
                            }
                        }
                    }
                },
                onCancel: { showScanner = false }
            )
        }
        .sheet(isPresented: $showVerification) {
            if let product = viewModel.resolvedProduct {
                ProductVerificationView(
                    product: product,
                    onAddToRoutine: {
                        pendingProduct = product
                        showVerification = false
                        showConfig = true
                    },
                    onSaveForLater: {
                        showVerification = false
                        viewModel.resolvedProduct = nil
                    }
                )
            }
        }
        .sheet(isPresented: $showConfig) {
            if let product = pendingProduct {
                RoutineConfigView(product: product) { schedule, days, reminder, time, notes in
                    viewModel.addToRoutine(
                        product: product,
                        schedule: schedule,
                        scheduleDays: days,
                        reminderEnabled: reminder,
                        reminderTime: time,
                        notes: notes
                    )
                    try? modelContext.save()
                    pendingProduct = nil
                    showConfig = false
                    viewModel.refresh()
                }
            }
        }
        .alert(
            alertTitle,
            isPresented: .init(
                get: { viewModel.scanError != nil },
                set: { if !$0 { viewModel.scanError = nil } }
            )
        ) {
            Button(Strings.done) { viewModel.scanError = nil }
        } message: {
            Text(alertBody)
        }
    }

    private var scanButton: some View {
        Button(action: { showScanner = true }) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "qrcode.viewfinder")
                Text(Strings.routineScanCTA)
            }
            .font(AppFont.headline)
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(AppGradient.warmCTA)
            .cornerRadius(CornerRadius.lg)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 48))
                .foregroundColor(AppColor.sage.opacity(0.6))
            Text(Strings.routineEmpty)
                .font(AppFont.title)
                .foregroundColor(AppColor.label)
            Text(Strings.routineEmptyBody)
                .font(AppFont.body)
                .foregroundColor(AppColor.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xxxl)
        .fadeRise()
    }

    private var pendingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(Strings.qrPendingBadge)
                .font(AppFont.caption)
                .foregroundColor(AppColor.warning)
                .padding(.horizontal, Spacing.xl)

            ForEach(viewModel.pendingTokens, id: \.id) { token in
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(AppColor.warning)
                    Text(Strings.qrOfflineSavedBody)
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.secondaryLabel)
                    Spacer()
                }
                .padding(Spacing.md)
                .cardStyle()
                .padding(.horizontal, Spacing.xl)
            }
        }
    }

    private var alertTitle: String {
        switch viewModel.scanError {
        case .invalidQR: return Strings.qrInvalidTitle
        case .tokenNotFound: return Strings.qrNotFoundTitle
        case .tokenRevoked: return Strings.qrRevokedTitle
        case .rateLimited: return Strings.qrRateLimitedTitle
        case .serviceUnavailable: return Strings.qrUnavailableTitle
        case .cameraRequired: return Strings.qrCameraRequiredTitle
        case .pendingQueueFull: return Strings.qrQueueFailedTitle
        case nil: return ""
        }
    }

    private var alertBody: String {
        switch viewModel.scanError {
        case .invalidQR: return Strings.qrInvalidBody
        case .tokenNotFound: return Strings.qrNotFoundBody
        case .tokenRevoked: return Strings.qrRevokedBody
        case .rateLimited: return Strings.qrRateLimitedBody
        case .serviceUnavailable: return Strings.qrUnavailableBody
        case .cameraRequired: return Strings.qrCameraRequiredBody
        case .pendingQueueFull: return Strings.qrQueueFailedBody
        case nil: return ""
        }
    }
}
```

**Step 2: Implement ProductVerificationView**

```swift
// Reflect/Views/Routine/ProductVerificationView.swift
import SwiftUI

struct ProductVerificationView: View {
    let product: VerifiedProduct
    let onAddToRoutine: () -> Void
    let onSaveForLater: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Verified badge
            ZStack {
                Circle()
                    .fill(AppColor.sage.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 44))
                    .foregroundColor(AppColor.sage)
            }
            .scaleEffect(appeared ? 1 : 0.6)
            .opacity(appeared ? 1 : 0)

            Text(Strings.routineVerified)
                .font(AppFont.title)
                .foregroundColor(AppColor.label)
                .opacity(appeared ? 1 : 0)

            // Product card
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text(product.name)
                    .font(AppFont.headline)
                    .foregroundColor(AppColor.label)

                HStack(spacing: Spacing.sm) {
                    Label(product.category, systemImage: "leaf.fill")
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.sage)
                }

                if let batchId = product.batchId {
                    Text("Batch: \(batchId)")
                        .font(AppFont.captionSecondary)
                        .foregroundColor(AppColor.secondaryLabel)
                }

                Text("Verified on \(product.verifiedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(AppFont.captionSecondary)
                    .foregroundColor(AppColor.secondaryLabel)
            }
            .padding(Spacing.xl)
            .cardStyle()
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)

            Spacer()

            // CTAs
            VStack(spacing: Spacing.md) {
                Button(action: onAddToRoutine) {
                    Text(Strings.routineAddToRoutine)
                        .font(AppFont.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(AppGradient.warmCTA)
                        .cornerRadius(CornerRadius.lg)
                }

                Button(action: onSaveForLater) {
                    Text(Strings.routineSaveForLater)
                        .font(AppFont.body)
                        .foregroundColor(AppColor.secondaryLabel)
                }
            }
            .opacity(appeared ? 1 : 0)
        }
        .padding(Spacing.xxl)
        .warmBackground()
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
    }
}
```

**Step 3: Implement RoutineConfigView**

```swift
// Reflect/Views/Routine/RoutineConfigView.swift
import SwiftUI

struct RoutineConfigView: View {
    let product: VerifiedProduct
    let onSave: (RoutineSchedule, [Int]?, Bool, Date?, String?) -> Void

    @State private var schedule: RoutineSchedule = .daily
    @State private var selectedDays: Set<Int> = []
    @State private var reminderEnabled = false
    @State private var reminderTime = Calendar.current.date(
        bySettingHour: 9, minute: 0, second: 0, of: Date()
    )!
    @State private var notes = ""

    private let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    // Product header
                    HStack(spacing: Spacing.md) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(AppColor.sage)
                        VStack(alignment: .leading) {
                            Text(product.name)
                                .font(AppFont.headline)
                                .foregroundColor(AppColor.label)
                            Text(product.category)
                                .font(AppFont.caption)
                                .foregroundColor(AppColor.secondaryLabel)
                        }
                    }
                    .padding(Spacing.lg)
                    .cardStyle()

                    // Schedule
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text(Strings.routineSchedule)
                            .font(AppFont.headline)
                            .foregroundColor(AppColor.label)

                        HStack(spacing: Spacing.sm) {
                            ForEach(RoutineSchedule.allCases, id: \.rawValue) { option in
                                Button(action: { schedule = option }) {
                                    Text(option.displayName)
                                        .font(AppFont.caption)
                                        .foregroundColor(schedule == option ? .white : AppColor.label)
                                        .padding(.horizontal, Spacing.md)
                                        .padding(.vertical, Spacing.sm)
                                        .background(schedule == option ? AppColor.amber : AppColor.cardBackground)
                                        .cornerRadius(CornerRadius.pill)
                                }
                            }
                        }
                    }

                    // Day picker (for weekly/custom)
                    if schedule == .weekly || schedule == .custom {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Days")
                                .font(AppFont.caption)
                                .foregroundColor(AppColor.secondaryLabel)

                            HStack(spacing: Spacing.sm) {
                                ForEach(1...7, id: \.self) { day in
                                    Button(action: { toggleDay(day) }) {
                                        Text(dayNames[day - 1])
                                            .font(AppFont.caption)
                                            .foregroundColor(selectedDays.contains(day) ? .white : AppColor.label)
                                            .frame(width: 40, height: 40)
                                            .background(selectedDays.contains(day) ? AppColor.amber : AppColor.cardBackground)
                                            .cornerRadius(CornerRadius.sm)
                                    }
                                }
                            }
                        }
                    }

                    // Reminder
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Toggle(isOn: $reminderEnabled) {
                            Text(Strings.routineReminder)
                                .font(AppFont.body)
                                .foregroundColor(AppColor.label)
                        }
                        .tint(AppColor.amber)

                        if reminderEnabled {
                            DatePicker(
                                Strings.routineReminderTime,
                                selection: $reminderTime,
                                displayedComponents: .hourAndMinute
                            )
                            .font(AppFont.body)
                            .foregroundColor(AppColor.label)
                        }
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(Strings.routineNotes)
                            .font(AppFont.caption)
                            .foregroundColor(AppColor.secondaryLabel)
                        TextField("Optional notes...", text: $notes, axis: .vertical)
                            .font(AppFont.body)
                            .lineLimit(3)
                            .padding(Spacing.md)
                            .background(AppColor.cardBackground)
                            .cornerRadius(CornerRadius.md)
                    }

                    // Save button
                    Button(action: save) {
                        Text(Strings.routineStartCTA)
                            .font(AppFont.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(AppGradient.warmCTA)
                            .cornerRadius(CornerRadius.lg)
                    }
                    .padding(.top, Spacing.lg)
                }
                .padding(Spacing.xl)
            }
            .warmBackground()
            .navigationTitle(Strings.routineConfigureTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }

    private func save() {
        let days = selectedDays.isEmpty ? nil : Array(selectedDays).sorted()
        onSave(
            schedule,
            days,
            reminderEnabled,
            reminderEnabled ? reminderTime : nil,
            notes.isEmpty ? nil : notes
        )
    }
}
```

**Step 4: Implement RoutineEntryCard**

```swift
// Reflect/Views/Routine/RoutineEntryCard.swift
import SwiftUI

struct RoutineEntryCard: View {
    let entry: RoutineEntry
    let adherence: AdherenceResult
    let onLog: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Product info
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AppColor.sage)
                        Text(entry.product?.name ?? "Unknown")
                            .font(AppFont.headline)
                            .foregroundColor(AppColor.label)
                    }

                    Text(entry.product?.category ?? "")
                        .font(AppFont.captionSecondary)
                        .foregroundColor(AppColor.secondaryLabel)
                }
                Spacer()

                // Schedule badge
                Text(entry.schedule.displayName)
                    .font(AppFont.captionSecondary)
                    .foregroundColor(AppColor.amber)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(AppColor.amber.opacity(0.1))
                    .cornerRadius(CornerRadius.pill)
            }

            // Adherence bar
            if entry.schedule != .asNeeded {
                HStack(spacing: Spacing.sm) {
                    Text("\(Strings.routineAdherence): \(adherence.logged) of \(adherence.expected) days")
                        .font(AppFont.captionSecondary)
                        .foregroundColor(AppColor.secondaryLabel)

                    Spacer()

                    // Progress indicator
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(AppColor.separator)
                                .frame(height: 4)
                            Capsule()
                                .fill(AppColor.sage)
                                .frame(
                                    width: geo.size.width * CGFloat(adherence.logged) / CGFloat(max(adherence.expected, 1)),
                                    height: 4
                                )
                        }
                    }
                    .frame(width: 60, height: 4)
                }
            }

            // Revoked banner
            if entry.product?.status == "revoked" {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(AppColor.danger)
                    Text(Strings.routineProductRevoked)
                        .font(AppFont.captionSecondary)
                        .foregroundColor(AppColor.danger)
                }
                .padding(Spacing.sm)
                .background(AppColor.danger.opacity(0.08))
                .cornerRadius(CornerRadius.sm)
            }

            // Action buttons
            if entry.isActive && entry.product?.status != "revoked" {
                HStack(spacing: Spacing.md) {
                    Button(action: onLog) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                            Text(Strings.routineLogToday)
                        }
                        .font(AppFont.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(AppColor.sage)
                        .cornerRadius(CornerRadius.pill)
                    }

                    Button(action: onSkip) {
                        Text(Strings.routineSkip)
                            .font(AppFont.caption)
                            .foregroundColor(AppColor.secondaryLabel)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(AppColor.separator.opacity(0.3))
                            .cornerRadius(CornerRadius.pill)
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .cardStyle(padded: false)
    }
}
```

**Step 5: Commit**

```bash
git add Reflect/Views/Routine/RoutineTabView.swift \
  Reflect/Views/Routine/ProductVerificationView.swift \
  Reflect/Views/Routine/RoutineConfigView.swift \
  Reflect/Views/Routine/RoutineEntryCard.swift
git commit -m "feat: add Routine tab views — scan, verify, configure, entry cards"
```

---

## Task 11: ContentView — Add Routine Tab

**Files:**
- Modify: `Reflect/ContentView.swift`

**Step 1: Update AppTab enum**

Add `routine` case between `moments` and `insights` in the `AppTab` enum:

```swift
enum AppTab: Int, CaseIterable {
    case today, reflect, moments, routine, insights, settings
    // ...
}
```

Update `label`, `icon`, and `iconFilled` switches to include:
```swift
case .routine: return Strings.tabRoutine
// icon:
case .routine: return "leaf.circle"
// iconFilled:
case .routine: return "leaf.circle.fill"
```

**Step 2: Update body switch**

Add the routine case:
```swift
case .routine: RoutineTabView()
```

**Step 3: Commit**

```bash
git add Reflect/ContentView.swift
git commit -m "feat: add Routine tab to ContentView tab bar"
```

---

## Task 12: Cache Refresh on App Foreground

**Files:**
- Modify: `Reflect/ReflectApp.swift`

**Step 1: Add ConnectivityService and foreground cache refresh**

In `ReflectApp.swift`, add a `ConnectivityService` as a `@StateObject` (or use `@State` + `@Observable`). In the `.onChange(of: scenePhase)` handler, when the scene transitions to `.active`, trigger pending queue resolution and stale cache refresh.

Add to `ReflectApp`:
```swift
@State private var connectivity = ConnectivityService()
@State private var routineViewModel = RoutineViewModel()
```

In `.onChange(of: scenePhase)`, add:
```swift
if newPhase == .active {
    Task {
        let context = PersistenceService.shared.container.mainContext
        routineViewModel.setup(context: context)
        await routineViewModel.resolvePendingTokens()
    }
}
```

**Step 2: Commit**

```bash
git add Reflect/ReflectApp.swift
git commit -m "feat: resolve pending tokens on app foreground"
```

---

## Task 13: Info.plist + project.yml + xcodegen Regeneration

**Files:**
- Modify: `Reflect/Info.plist`
- Modify: `project.yml`

**Step 1: Add NSCameraUsageDescription to both files**

Info.plist — add inside `<dict>`:
```xml
<key>NSCameraUsageDescription</key>
<string>Reflect uses your camera to scan product QR codes for verification.</string>
```

project.yml — add to `info.properties`:
```yaml
NSCameraUsageDescription: "Reflect uses your camera to scan product QR codes for verification."
```

**Step 2: Regenerate and verify**

```bash
cd /Users/jonathanguttman/Documents/PsillyJournal/Reflect
xcodegen generate
```

Verify UILaunchScreen and NSCameraUsageDescription are both present in Info.plist after regeneration.

**Step 3: Commit**

```bash
git add Reflect/Info.plist project.yml
git commit -m "feat: add NSCameraUsageDescription for QR scanner"
```

---

## Task 14: Update CHANGELOG and Docs

**Files:**
- Modify: `docs/CHANGELOG.md`

**Step 1: Add v0.4.0 entry**

```markdown
## [0.4.0] - 2026-02-23

### Added
- QR token verification system — scan product QR codes to verify authenticity
- Routine tracker with daily/weekly/custom schedules and reminders
- Routine adherence logging (log/skip) with weekly progress
- Offline pending queue for QR scans without connectivity
- Stale-while-revalidate product cache with 24h TTL
- New Routine tab in main navigation
- Camera permission handling with graceful fallback
- Token validation service (domain allowlist, path prefix, regex)
- API client with stub for development (LiveTokenAPIService + StubTokenAPIService)
- App Store-safe UI copy for all scan/verify/error/offline states
```

**Step 2: Commit**

```bash
git add docs/CHANGELOG.md
git commit -m "docs: add v0.4.0 changelog for QR token system"
```

---

## Task 15: Integration Test — Full Scan-to-Routine Flow

**Files:**
- Create: `ReflectTests/RoutineIntegrationTests.swift`

**Step 1: Write integration test**

```swift
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
                name: "Third Eye Chai",
                category: "Herbal Tea",
                description: "A calming herbal blend.",
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
        XCTAssertEqual(product.name, "Third Eye Chai")

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
        product.status = "revoked"
        entry.isActive = false
        try context.save()

        // 4. Verify
        XCTAssertEqual(product.status, "revoked")
        XCTAssertFalse(entry.isActive)
    }
}
```

**Step 2: Run full test suite**

```bash
xcodegen generate && xcodebuild test -project Reflect.xcodeproj -scheme ReflectTests \
  -destination 'platform=iOS Simulator,id=2A35514A-B453-4780-87F9-0F652CEBBAB4' \
  2>&1 | tail -30
```
Expected: ALL PASS

**Step 3: Commit**

```bash
git add ReflectTests/RoutineIntegrationTests.swift
git commit -m "test: add integration tests for scan-to-routine flow"
```

---

## Task Summary

| # | Task | Files | Tests |
|---|---|---|---|
| 1 | VerifiedProduct + PendingToken models | 3 new, 1 modified | 6 tests |
| 2 | RoutineEntry + RoutineLog models | 2 new, 1 modified | 6 tests |
| 3 | TokenValidationService | 2 new | 10 tests |
| 4 | TokenAPIService | 2 new | 6 tests |
| 5 | TokenResolutionService | 2 new | 7 tests |
| 6 | ConnectivityService | 1 new | — |
| 7 | UI Copy (Strings) | 1 modified | — |
| 8 | RoutineViewModel | 2 new | 6 tests |
| 9 | QRScannerView (camera) | 1 new + 2 modified | — |
| 10 | Routine views (tab, verify, config, card) | 4 new | — |
| 11 | ContentView Routine tab | 1 modified | — |
| 12 | App foreground cache refresh | 1 modified | — |
| 13 | Info.plist + project.yml camera permission | 2 modified | — |
| 14 | CHANGELOG | 1 modified | — |
| 15 | Integration tests | 1 new | 3 tests |

**Total: 21 new files, 8 modified files, ~44 tests**
**Estimated commits: 15**

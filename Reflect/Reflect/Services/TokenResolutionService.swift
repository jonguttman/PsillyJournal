// Reflect/Services/TokenResolutionService.swift
import Foundation
import SwiftData

enum TokenResolutionError: Error, Equatable {
    case pendingQueueFull
}

// MARK: - Pending Queue Policy
// Maximum 5 pending tokens. When full, the app shows a hard fail with clear UX copy:
// "We couldn't verify this product. You can try scanning it again."
// We chose Option B (hard fail) over Option A (evict oldest) because:
// - 5 is already generous for offline scanning
// - Silently evicting tokens could confuse users who expect them to resolve
// - The error message is actionable ("try scanning again")

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
            existing.status = VerifiedProductStatus(rawValue: response.status) ?? .active
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

        // Check queue limit using rawValue for SwiftData predicate compatibility
        let pendingRaw = PendingTokenStatus.pending.rawValue
        let countDescriptor = FetchDescriptor<PendingToken>(
            predicate: #Predicate { $0.statusRaw == pendingRaw }
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
        let pendingRaw = PendingTokenStatus.pending.rawValue
        let maxRetries = 3
        let descriptor = FetchDescriptor<PendingToken>(
            predicate: #Predicate { $0.statusRaw == pendingRaw && $0.retryCount < maxRetries },
            sortBy: [SortDescriptor(\.scannedAt)]
        )
        return try context.fetch(descriptor)
    }

    static func removePendingToken(_ token: PendingToken, context: ModelContext) {
        context.delete(token)
    }
}

// Reflect/Models/VerifiedProduct.swift
import Foundation
import SwiftData

enum VerifiedProductStatus: String, Codable {
    case active
    case revoked
}

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
    var statusRaw: String

    var status: VerifiedProductStatus {
        get { VerifiedProductStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

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
        status: VerifiedProductStatus = .active
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
        self.statusRaw = status.rawValue
    }
}

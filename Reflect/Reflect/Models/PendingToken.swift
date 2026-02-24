// Reflect/Models/PendingToken.swift
import Foundation
import SwiftData

enum PendingTokenStatus: String, Codable {
    case pending
    case resolving
    case failed
}

@Model
final class PendingToken {
    var id: UUID
    var token: String
    var scannedAt: Date
    var retryCount: Int
    var lastRetryAt: Date?
    var statusRaw: String

    var status: PendingTokenStatus {
        get { PendingTokenStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    init(
        token: String,
        scannedAt: Date = Date(),
        retryCount: Int = 0,
        lastRetryAt: Date? = nil,
        status: PendingTokenStatus = .pending
    ) {
        self.id = UUID()
        self.token = token
        self.scannedAt = scannedAt
        self.retryCount = retryCount
        self.lastRetryAt = lastRetryAt
        self.statusRaw = status.rawValue
    }
}

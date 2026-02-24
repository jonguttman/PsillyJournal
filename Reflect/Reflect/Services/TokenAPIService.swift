// Reflect/Services/TokenAPIService.swift
import Foundation
import CryptoKit
#if canImport(UIKit)
import UIKit
#endif

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

    // IMPORTANT: UIKit must be imported at the top of this file via #if canImport(UIKit).
    // Do NOT place `import UIKit` inside this function — it won't compile.
    // identifierForVendor can change if all vendor apps are uninstalled/reinstalled.
    // This is acceptable for rate limiting (non-security-critical).
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

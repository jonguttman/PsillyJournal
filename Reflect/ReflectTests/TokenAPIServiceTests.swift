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
                "name": "Chamomile Calm Blend",
                "category": "Herbal Tea",
                "description": "A soothing herbal tea blend.",
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
        XCTAssertEqual(response.product.name, "Chamomile Calm Blend")
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

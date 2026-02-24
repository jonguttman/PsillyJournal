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
        let result = TokenValidationService.extractToken(from: "")
        XCTAssertEqual(result, .failure(.malformedURL))
    }

    func testNonHTTPSStringRejected() {
        let result = TokenValidationService.extractToken(from: "not a url at all")
        // URL(string:) may parse this — either malformedURL or invalidScheme is acceptable
        switch result {
        case .failure(.malformedURL), .failure(.invalidScheme):
            break // expected
        default:
            XCTFail("Expected malformedURL or invalidScheme, got \(result)")
        }
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

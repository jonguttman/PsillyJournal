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

        let path = url.path
        // url.path strips trailing slashes, so "/t/" becomes "/t"
        guard path.hasPrefix(requiredPathPrefix) || path == "/t" else {
            return .failure(.invalidPath)
        }

        // If path is exactly "/t", there's no token
        guard path.hasPrefix(requiredPathPrefix) else {
            return .failure(.invalidTokenFormat)
        }

        let tokenPart = String(path.dropFirst(requiredPathPrefix.count))
        let token = tokenPart.hasSuffix("/") ? String(tokenPart.dropLast()) : tokenPart

        guard isValidToken(token) else {
            return .failure(.invalidTokenFormat)
        }

        return .success(token)
    }
}

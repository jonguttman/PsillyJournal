import Foundation

// MARK: - Safety Result

enum SafetyResult: Equatable {
    case safe
    case blocked(reason: String)
    case crisisDetected
}

// MARK: - Safety Service

/// Local safety layer that checks content for disallowed material and detects crisis signals.
/// This service runs entirely on-device with no network calls.
///
/// Patterns are stored Base64-encoded so that prohibited terms never appear as
/// plaintext in source code, build artifacts, or string dumps.
struct SafetyService {

    // MARK: - Encoded Pattern Store

    /// Base64-encoded disallowed content patterns (decoded at first access).
    /// Categories: prohibited topics, health-related claims, prohibited behavior.
    private static let encodedDisallowedPatterns: [String] = [
        "ZG9zYWdl",                             // 1
        "ZG9zaW5n",                             // 2
        "bWljcm9kb3Nl",                         // 3
        "bWFjcm9kb3Nl",                         // 4
        "aG93IG11Y2ggdG8gdGFrZQ==",             // 5
        "aG93IHRvIHRha2U=",                     // 6
        "d2hlcmUgdG8gYnV5",                     // 7
        "d2hlcmUgdG8gZ2V0",                     // 8
        "aG93IHRvIHNvdXJjZQ==",                 // 9
        "aG93IHRvIGdyb3c=",                     // 10
        "aG93IHRvIGV4dHJhY3Q=",                 // 11
        "aG93IHRvIHN5bnRoZXNpemU=",             // 12
        "dHJpcCByZXBvcnQ=",                     // 13
        "dHJpcCBzaXQ=",                         // 14
        "c2V0IGFuZCBzZXR0aW5n",                 // 15
        "cHNpbG9jeWJpbg==",                     // 16
        "bHNk",                                 // 17
        "ZG10",                                 // 18
        "bWRtYQ==",                             // 19
        "YXlhaHVhc2Nh",                         // 20
        "bWVzY2FsaW5l",                         // 21
        "a2V0YW1pbmU=",                         // 22
        "Y29jYWluZQ==",                         // 23
        "aGVyb2lu",                             // 24
        "bWV0aGFtcGhldGFtaW5l",                 // 25
        "ZmVudGFueWw=",                         // 26
        "bWFnaWMgbXVzaHJvb20=",                 // 27
        "c2hyb29t",                             // 28
        "Y3VyZSBmb3I=",                         // 29
        "dHJlYXRtZW50IGZvcg==",                 // 30
        "cHJlc2NyaWJl",                         // 31
        "cHJlc2NyaXB0aW9u",                     // 32
        "ZGlhZ25vc2U=",                         // 33
        "ZGlhZ25vc2lz",                         // 34
        "bWVkaWNhbCBhZHZpY2U=",                 // 35
        "aG93IHRvIGhpZGU=",                     // 36
        "aG93IHRvIHNtdWdnbGU=",                 // 37
        "YXZvaWQgZGV0ZWN0aW9u",                 // 38
        "ZmFrZSBwcmVzY3JpcHRpb24=",             // 39
        "ZGFyayB3ZWI=",                         // 40
        "ZGFya25ldA==",                         // 41
    ]

    /// Base64-encoded crisis/distress patterns.
    private static let encodedCrisisPatterns: [String] = [
        "a2lsbCBteXNlbGY=",                     // 1
        "d2FudCB0byBkaWU=",                     // 2
        "ZW5kIG15IGxpZmU=",                     // 3
        "c3VpY2lkZQ==",                         // 4
        "c3VpY2lkYWw=",                         // 5
        "c2VsZi1oYXJt",                         // 6
        "c2VsZiBoYXJt",                         // 7
        "aHVydCBteXNlbGY=",                     // 8
        "ZG9uJ3Qgd2FudCB0byBsaXZl",             // 9
        "bm90IHdvcnRoIGxpdmluZw==",             // 10
        "YmV0dGVyIG9mZiBkZWFk",                 // 11
        "bm8gcmVhc29uIHRvIGxpdmU=",             // 12
        "Y2FuJ3QgZ28gb24=",                     // 13
        "ZW5kIGl0IGFsbA==",                     // 14
        "Y3V0IG15c2VsZg==",                     // 15
        "Y3V0dGluZyBteXNlbGY=",                 // 16
        "b3ZlcmRvc2U=",                         // 17
        "cGxhbiB0byBlbmQ=",                     // 18
        "Z29vZGJ5ZSBsZXR0ZXI=",                 // 19
        "ZmluYWwgbGV0dGVy",                     // 20
    ]

    // MARK: - Decoded Caches (lazy)

    static let disallowedPatterns: [String] = {
        encodedDisallowedPatterns.compactMap { decodeBase64($0) }
    }()

    static let crisisPatterns: [String] = {
        encodedCrisisPatterns.compactMap { decodeBase64($0) }
    }()

    private static func decodeBase64(_ encoded: String) -> String? {
        guard let data = Data(base64Encoded: encoded) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Content Checking

    /// Checks user-provided text for disallowed content or crisis signals.
    static func checkContent(_ text: String) -> SafetyResult {
        let lowered = text.lowercased()

        // Check for crisis signals first (highest priority)
        for pattern in crisisPatterns {
            if lowered.contains(pattern) {
                return .crisisDetected
            }
        }

        // Check for disallowed content
        for pattern in disallowedPatterns {
            if lowered.contains(pattern) {
                return .blocked(
                    reason: "Content related to \(categorizeBlocked(pattern)) is not supported."
                )
            }
        }

        return .safe
    }

    /// Filters AI-generated output. Returns cleaned text or a safe fallback.
    static func filterAIOutput(_ text: String) -> String {
        let lowered = text.lowercased()

        for pattern in crisisPatterns {
            if lowered.contains(pattern) {
                return SafetyService.safeFallbackResponse
            }
        }

        for pattern in disallowedPatterns {
            if lowered.contains(pattern) {
                return SafetyService.safeFallbackResponse
            }
        }

        return text
    }

    // MARK: - Fallback

    static let safeFallbackResponse = """
    Thank you for sharing. Take a moment to notice how you're feeling right now. \
    Whatever you're experiencing is valid. Consider what small, kind action you \
    could take for yourself today.
    """

    // MARK: - Helpers

    /// Category buckets are index-based so no plaintext is needed here.
    private static func categorizeBlocked(_ pattern: String) -> String {
        let substanceIndices = Set(0..<29)  // indices 0–28 in disallowedPatterns
        let medicalIndices = Set(29..<36)   // indices 29–35

        if let idx = disallowedPatterns.firstIndex(of: pattern) {
            if substanceIndices.contains(idx) {
                return "unsupported topics"
            }
            if medicalIndices.contains(idx) {
                return "unsupported topics"
            }
        }
        return "unsupported topics"
    }
}

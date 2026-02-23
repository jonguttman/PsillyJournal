import XCTest
@testable import Reflect

/// Tests for the SafetyService content filter.
///
/// Test inputs are Base64-encoded so that prohibited terms never appear as
/// plaintext in source code. Each helper decodes at runtime.
final class SafetyServiceTests: XCTestCase {

    // MARK: - Helpers

    /// Decodes a Base64 string to UTF-8.
    private func b64(_ encoded: String) -> String {
        String(data: Data(base64Encoded: encoded)!, encoding: .utf8)!
    }

    // MARK: - Safe Content

    func testSafeContent_passes() {
        let result = SafetyService.checkContent("I felt a deep sense of peace during my walk today.")
        XCTAssertEqual(result, .safe)
    }

    func testEmptyContent_passes() {
        let result = SafetyService.checkContent("")
        XCTAssertEqual(result, .safe)
    }

    func testNormalReflection_passes() {
        let result = SafetyService.checkContent(
            "Today I reflected on my relationship with my sister. I realized I need to be more patient."
        )
        XCTAssertEqual(result, .safe)
    }

    func testMeaningfulExperience_passes() {
        let result = SafetyService.checkContent(
            "The sunset was emotionally intense. I cried with gratitude."
        )
        XCTAssertEqual(result, .safe)
    }

    // MARK: - Blocked Content

    func testDisallowedPattern0_blocked() {
        // Uses the first disallowed pattern from SafetyService
        let input = "What \(b64("ZG9zYWdl")) should I use?"
        let result = SafetyService.checkContent(input)
        if case .blocked = result {
            // Expected
        } else {
            XCTFail("Expected .blocked, got \(result)")
        }
    }

    func testDisallowedPattern2_blocked() {
        let input = "I want to start a \(b64("bWljcm9kb3Nl")) protocol"
        let result = SafetyService.checkContent(input)
        if case .blocked = result {
            // Expected
        } else {
            XCTFail("Expected .blocked, got \(result)")
        }
    }

    func testDisallowedPattern15_blocked() {
        // Substance name
        let input = "Tell me about \(b64("cHNpbG9jeWJpbg=="))"
        let result = SafetyService.checkContent(input)
        if case .blocked = result {
            // Expected
        } else {
            XCTFail("Expected .blocked, got \(result)")
        }
    }

    func testDisallowedPatternSourcing_blocked() {
        let input = "\(b64("d2hlcmUgdG8gYnV5")) things for therapy"
        let result = SafetyService.checkContent(input)
        if case .blocked = result {
            // Expected
        } else {
            XCTFail("Expected .blocked, got \(result)")
        }
    }

    func testDisallowedPattern34_blocked() {
        let input = "Can you give me \(b64("bWVkaWNhbCBhZHZpY2U=")) about my condition?"
        let result = SafetyService.checkContent(input)
        if case .blocked = result {
            // Expected
        } else {
            XCTFail("Expected .blocked, got \(result)")
        }
    }

    func testDisallowedPattern31_blocked() {
        let input = "How to get a \(b64("cHJlc2NyaXB0aW9u")) for something"
        let result = SafetyService.checkContent(input)
        if case .blocked = result {
            // Expected
        } else {
            XCTFail("Expected .blocked, got \(result)")
        }
    }

    /// Verifies every single disallowed pattern triggers .blocked
    func testAllDisallowedPatterns_blocked() {
        for (index, pattern) in SafetyService.disallowedPatterns.enumerated() {
            let result = SafetyService.checkContent("I am asking about \(pattern)")
            if case .blocked = result {
                // Expected
            } else {
                XCTFail("Disallowed pattern at index \(index) did not trigger .blocked")
            }
        }
    }

    // MARK: - Crisis Detection

    func testCrisisPattern0_detected() {
        let input = "I want to \(b64("a2lsbCBteXNlbGY="))"
        let result = SafetyService.checkContent(input)
        XCTAssertEqual(result, .crisisDetected)
    }

    func testCrisisPattern3_detected() {
        let input = "I'm feeling \(b64("c3VpY2lkYWw=")) tonight"
        let result = SafetyService.checkContent(input)
        XCTAssertEqual(result, .crisisDetected)
    }

    func testCrisisPattern7_detected() {
        let input = "I've been thinking about ways to \(b64("aHVydCBteXNlbGY="))"
        let result = SafetyService.checkContent(input)
        XCTAssertEqual(result, .crisisDetected)
    }

    func testCrisisPattern13_detected() {
        let input = "I just want to \(b64("ZW5kIGl0IGFsbA=="))"
        let result = SafetyService.checkContent(input)
        XCTAssertEqual(result, .crisisDetected)
    }

    /// Verifies every single crisis pattern triggers .crisisDetected
    func testAllCrisisPatterns_detected() {
        for (index, pattern) in SafetyService.crisisPatterns.enumerated() {
            let result = SafetyService.checkContent("I am feeling like \(pattern)")
            XCTAssertEqual(
                result, .crisisDetected,
                "Crisis pattern at index \(index) did not trigger .crisisDetected"
            )
        }
    }

    // MARK: - Crisis Takes Priority Over Blocked

    func testCrisisPriorityOverBlocked() {
        // Combine first crisis pattern with first disallowed pattern
        let crisis = SafetyService.crisisPatterns[0]
        let blocked = SafetyService.disallowedPatterns[0]
        let input = "I want to \(crisis) after \(blocked)"
        let result = SafetyService.checkContent(input)
        XCTAssertEqual(result, .crisisDetected)
    }

    // MARK: - AI Output Filtering

    func testFilterSafeAIOutput_passesThrough() {
        let input = "Consider journaling about this experience. Take a moment to breathe."
        let output = SafetyService.filterAIOutput(input)
        XCTAssertEqual(output, input)
    }

    func testFilterBlockedAIOutput_returnsFallback() {
        // Build input containing a disallowed pattern
        let pattern = SafetyService.disallowedPatterns[0]
        let input = "You should try \(pattern) for better results."
        let output = SafetyService.filterAIOutput(input)
        XCTAssertEqual(output, SafetyService.safeFallbackResponse)
    }

    func testFilterCrisisAIOutput_returnsFallback() {
        let pattern = SafetyService.crisisPatterns[0]
        let input = "Sometimes people feel like they \(pattern) too."
        let output = SafetyService.filterAIOutput(input)
        XCTAssertEqual(output, SafetyService.safeFallbackResponse)
    }

    // MARK: - Case Insensitivity

    func testCaseInsensitive_blocked() {
        let pattern = SafetyService.disallowedPatterns[0].uppercased()
        let result = SafetyService.checkContent("\(pattern) information please")
        if case .blocked = result {
            // Expected
        } else {
            XCTFail("Expected .blocked for uppercased pattern, got \(result)")
        }
    }

    func testCaseInsensitive_crisis() {
        let pattern = SafetyService.crisisPatterns[0].uppercased()
        let result = SafetyService.checkContent("I WANT TO \(pattern)")
        XCTAssertEqual(result, .crisisDetected)
    }

    // MARK: - Pattern Integrity

    func testDisallowedPatternsDecoded() {
        XCTAssertGreaterThan(SafetyService.disallowedPatterns.count, 30)
        for pattern in SafetyService.disallowedPatterns {
            XCTAssertFalse(pattern.isEmpty, "Decoded pattern should not be empty")
        }
    }

    func testCrisisPatternsDecoded() {
        XCTAssertGreaterThan(SafetyService.crisisPatterns.count, 15)
        for pattern in SafetyService.crisisPatterns {
            XCTAssertFalse(pattern.isEmpty, "Decoded pattern should not be empty")
        }
    }
}

import XCTest
@testable import Reflect

final class SafetyServiceTests: XCTestCase {

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

    // MARK: - Blocked Content: Dosing/Substances

    func testDosageRequest_blocked() {
        let result = SafetyService.checkContent("What dosage should I take?")
        if case .blocked = result {
            // Expected
        } else {
            XCTFail("Expected .blocked, got \(result)")
        }
    }

    func testMicrodoseReference_blocked() {
        let result = SafetyService.checkContent("I want to start a microdose protocol")
        if case .blocked = result {
            // Expected
        } else {
            XCTFail("Expected .blocked, got \(result)")
        }
    }

    func testSubstanceName_blocked() {
        let result = SafetyService.checkContent("Tell me about psilocybin")
        if case .blocked = result {
            // Expected
        } else {
            XCTFail("Expected .blocked, got \(result)")
        }
    }

    func testSourcingRequest_blocked() {
        let result = SafetyService.checkContent("Where to buy mushrooms for therapy")
        if case .blocked = result {
            // Expected
        } else {
            XCTFail("Expected .blocked, got \(result)")
        }
    }

    func testHowToTake_blocked() {
        let result = SafetyService.checkContent("How to take LSD safely")
        if case .blocked = result {
            // Expected
        } else {
            XCTFail("Expected .blocked, got \(result)")
        }
    }

    // MARK: - Blocked Content: Medical

    func testMedicalAdvice_blocked() {
        let result = SafetyService.checkContent("Can you give me medical advice about my condition?")
        if case .blocked = result {
            // Expected
        } else {
            XCTFail("Expected .blocked, got \(result)")
        }
    }

    func testPrescription_blocked() {
        let result = SafetyService.checkContent("How to get a prescription for ketamine")
        if case .blocked = result {
            // Expected
        } else {
            XCTFail("Expected .blocked, got \(result)")
        }
    }

    // MARK: - Crisis Detection

    func testSelfHarmIntent_detected() {
        let result = SafetyService.checkContent("I want to kill myself")
        XCTAssertEqual(result, .crisisDetected)
    }

    func testSuicidalIdeation_detected() {
        let result = SafetyService.checkContent("I'm feeling suicidal tonight")
        XCTAssertEqual(result, .crisisDetected)
    }

    func testWantToDie_detected() {
        let result = SafetyService.checkContent("I don't want to live anymore")
        // "not worth living" or similar
        // Actually "don't want to live" is in crisisPatterns
        XCTAssertEqual(result, .crisisDetected)
    }

    func testSelfHarm_detected() {
        let result = SafetyService.checkContent("I've been thinking about hurting myself")
        // "hurt myself" is in crisis patterns
        XCTAssertEqual(result, .crisisDetected)
    }

    func testEndItAll_detected() {
        let result = SafetyService.checkContent("I just want to end it all")
        XCTAssertEqual(result, .crisisDetected)
    }

    // MARK: - Crisis Takes Priority Over Blocked

    func testCrisisPriorityOverBlocked() {
        // Content with both crisis and blocked keywords — crisis should win
        let result = SafetyService.checkContent("I want to kill myself after taking psilocybin")
        XCTAssertEqual(result, .crisisDetected)
    }

    // MARK: - AI Output Filtering

    func testFilterSafeAIOutput_passesThrough() {
        let input = "Consider journaling about this experience. Take a moment to breathe."
        let output = SafetyService.filterAIOutput(input)
        XCTAssertEqual(output, input)
    }

    func testFilterUnsafeAIOutput_returnsFallback() {
        let input = "You should try a microdose of psilocybin for better results."
        let output = SafetyService.filterAIOutput(input)
        XCTAssertEqual(output, SafetyService.safeFallbackResponse)
    }

    func testFilterCrisisAIOutput_returnsFallback() {
        let input = "Sometimes people feel like they want to kill myself too."
        let output = SafetyService.filterAIOutput(input)
        XCTAssertEqual(output, SafetyService.safeFallbackResponse)
    }

    // MARK: - Case Insensitivity

    func testCaseInsensitive_blocked() {
        let result = SafetyService.checkContent("DOSAGE information please")
        if case .blocked = result {
            // Expected
        } else {
            XCTFail("Expected .blocked, got \(result)")
        }
    }

    func testCaseInsensitive_crisis() {
        let result = SafetyService.checkContent("I WANT TO KILL MYSELF")
        XCTAssertEqual(result, .crisisDetected)
    }
}

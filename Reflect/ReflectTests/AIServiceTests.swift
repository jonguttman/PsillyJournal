import XCTest
@testable import Reflect

final class AIServiceTests: XCTestCase {

    let stubService = StubAIService()

    // MARK: - Stub Responses

    func testGroundingLens_gentleTone() async throws {
        let response = try await stubService.generateLensResponse(
            entryText: "I had a meaningful experience today",
            lensType: .grounding,
            tone: .gentle,
            avoidTopics: []
        )
        XCTAssertFalse(response.isEmpty)
        XCTAssertTrue(response.contains("breath") || response.contains("ground") || response.contains("notice"))
    }

    func testMeaningLens_directTone() async throws {
        let response = try await stubService.generateLensResponse(
            entryText: "Something changed in how I see relationships",
            lensType: .meaning,
            tone: .direct,
            avoidTopics: []
        )
        XCTAssertFalse(response.isEmpty)
        XCTAssertTrue(response.contains("interpretation") || response.contains("pattern") || response.contains("processing"))
    }

    func testIntegrationLens_gentleTone() async throws {
        let response = try await stubService.generateLensResponse(
            entryText: "I realized I need to express myself more creatively",
            lensType: .integration,
            tone: .gentle,
            avoidTopics: []
        )
        XCTAssertFalse(response.isEmpty)
        XCTAssertTrue(response.contains("7-day") || response.contains("habit") || response.contains("plan"))
    }

    // MARK: - Safety Filtering

    func testStubOutput_isSafetyFiltered() async throws {
        // The stub itself should produce safe content, but verify the filtering pipeline
        for lensType in LensType.allCases {
            let response = try await stubService.generateLensResponse(
                entryText: "Test entry",
                lensType: lensType,
                tone: .gentle,
                avoidTopics: []
            )
            // Verify the output would pass safety check
            let safetyResult = SafetyService.checkContent(response)
            XCTAssertEqual(safetyResult, .safe, "Stub response for \(lensType) should be safe")
        }
    }

    func testStubOutput_noDisallowedContent() async throws {
        for lensType in LensType.allCases {
            for tone in TonePreference.allCases {
                let response = try await stubService.generateLensResponse(
                    entryText: "Test",
                    lensType: lensType,
                    tone: tone,
                    avoidTopics: []
                )
                // Verify no disallowed patterns
                let lowered = response.lowercased()
                for pattern in SafetyService.disallowedPatterns {
                    XCTAssertFalse(
                        lowered.contains(pattern),
                        "Stub response contains disallowed pattern: \(pattern)"
                    )
                }
            }
        }
    }

    // MARK: - Tone Differences

    func testDifferentTones_produceDifferentResults() async throws {
        let gentleResponse = try await stubService.generateLensResponse(
            entryText: "Test",
            lensType: .grounding,
            tone: .gentle,
            avoidTopics: []
        )
        let directResponse = try await stubService.generateLensResponse(
            entryText: "Test",
            lensType: .grounding,
            tone: .direct,
            avoidTopics: []
        )
        XCTAssertNotEqual(gentleResponse, directResponse)
    }

    // MARK: - All Lens Types Return Content

    func testAllLensTypes_returnNonEmpty() async throws {
        for lensType in LensType.allCases {
            let response = try await stubService.generateLensResponse(
                entryText: "A meaningful reflection about life",
                lensType: lensType,
                tone: .gentle,
                avoidTopics: []
            )
            XCTAssertFalse(response.isEmpty, "\(lensType) returned empty response")
            XCTAssertGreaterThan(response.count, 50, "\(lensType) response suspiciously short")
        }
    }

    // MARK: - Live AI Service (Fallback)

    func testLiveAIService_fallsBackToStub() async throws {
        let liveService = LiveAIService()
        let response = try await liveService.generateLensResponse(
            entryText: "Test entry",
            lensType: .grounding,
            tone: .gentle,
            avoidTopics: []
        )
        XCTAssertFalse(response.isEmpty)
    }
}

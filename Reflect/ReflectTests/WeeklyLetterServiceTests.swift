import XCTest
@testable import Reflect

final class WeeklyLetterServiceTests: XCTestCase {

    // MARK: - Theme Extraction

    func testExtractTopThemes_fromSessions() {
        let sessions = [
            ReflectionSession(themeTags: ["Growth", "Connection", "Purpose"]),
            ReflectionSession(themeTags: ["Growth", "Nature"]),
            ReflectionSession(themeTags: ["Growth", "Connection"]),
        ]
        let themes = WeeklyLetterService.extractTopThemes(sessions: sessions, moments: [])
        XCTAssertEqual(themes.first, "Growth")
        XCTAssertTrue(themes.contains("Connection"))
        XCTAssertTrue(themes.count <= 3)
    }

    func testExtractTopThemes_fromMoments() {
        let moments = [
            Moment(themes: ["Wonder"], emotions: ["Awe"]),
            Moment(themes: ["Wonder", "Change"], emotions: ["Hope"]),
        ]
        let themes = WeeklyLetterService.extractTopThemes(sessions: [], moments: moments)
        XCTAssertEqual(themes.first, "Wonder")
    }

    func testExtractTopThemes_empty() {
        let themes = WeeklyLetterService.extractTopThemes(sessions: [], moments: [])
        XCTAssertTrue(themes.isEmpty)
    }

    // MARK: - Key Moments

    func testPickKeyMoments_fromMoments() {
        let moments = [
            Moment(quote: "The stars were incredible"),
            Moment(quote: "I finally understood forgiveness"),
        ]
        let result = WeeklyLetterService.pickKeyMoments(checkIns: [], sessions: [], moments: moments)
        XCTAssertTrue(result.contains("stars"))
        XCTAssertTrue(result.contains("forgiveness"))
    }

    func testPickKeyMoments_empty() {
        let result = WeeklyLetterService.pickKeyMoments(checkIns: [], sessions: [], moments: [])
        XCTAssertTrue(result.contains("No specific moments"))
    }

    func testPickKeyMoments_fromSessions() {
        let sessions = [
            ReflectionSession(
                title: "Morning walk",
                captureResponse: "The fog was lifting and I felt something shift"
            )
        ]
        let result = WeeklyLetterService.pickKeyMoments(checkIns: [], sessions: sessions, moments: [])
        XCTAssertTrue(result.contains("Morning walk"))
    }

    func testPickKeyMoments_maxThree() {
        let moments = [
            Moment(quote: "One"),
            Moment(quote: "Two"),
            Moment(quote: "Three"),
            Moment(quote: "Four"),
            Moment(quote: "Five"),
        ]
        let result = WeeklyLetterService.pickKeyMoments(checkIns: [], sessions: [], moments: moments)
        let lines = result.split(separator: "\n")
        XCTAssertLessThanOrEqual(lines.count, 3)
    }

    // MARK: - Questions

    func testGenerateQuestions_withThemes() {
        let themes = ["Growth", "Connection"]
        let checkIns = [CheckIn(mood: 7, energy: 6, stress: 3)]
        let result = WeeklyLetterService.generateQuestions(themes: themes, checkIns: checkIns)
        XCTAssertTrue(result.contains("growth"))
    }

    func testGenerateQuestions_highStress() {
        let themes = ["Work"]
        let checkIns = [
            CheckIn(stress: 8),
            CheckIn(stress: 9),
            CheckIn(stress: 7),
        ]
        let result = WeeklyLetterService.generateQuestions(themes: themes, checkIns: checkIns)
        XCTAssertTrue(result.contains("stress") || result.contains("let go"))
    }

    func testGenerateQuestions_empty() {
        let result = WeeklyLetterService.generateQuestions(themes: [], checkIns: [])
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - Commitment

    func testGenerateCommitment_fromSession() {
        let sessions = [
            ReflectionSession(nextStepResponse: "Call my mom this weekend")
        ]
        let result = WeeklyLetterService.generateCommitment(themes: [], sessions: sessions)
        XCTAssertEqual(result, "Call my mom this weekend")
    }

    func testGenerateCommitment_fromTheme() {
        let result = WeeklyLetterService.generateCommitment(themes: ["Creativity"], sessions: [])
        XCTAssertTrue(result.contains("creativity"))
    }

    func testGenerateCommitment_fallback() {
        let result = WeeklyLetterService.generateCommitment(themes: [], sessions: [])
        XCTAssertTrue(result.contains("five quiet minutes"))
    }

    // MARK: - Full Letter Generation

    func testGenerateLetter_withData() {
        let now = Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let checkIns = [
            CheckIn(mood: 7, energy: 6, stress: 4, sleepHours: 7.5, sleepQuality: 7, createdAt: now),
            CheckIn(mood: 8, energy: 7, stress: 3, sleepHours: 8.0, sleepQuality: 8, createdAt: now),
        ]
        let sessions = [
            ReflectionSession(
                title: "Evening reflection",
                themeTags: ["Gratitude"],
                captureResponse: "Grateful for the quiet evening",
                meaningResponse: "Peace is available",
                nextStepResponse: "Make space for quiet each day",
                createdAt: now
            )
        ]
        let moments = [
            Moment(quote: "Peace is always here", themes: ["Peace"], createdAt: now)
        ]

        let letter = WeeklyLetterService.generateLetter(
            checkIns: checkIns,
            sessions: sessions,
            moments: moments,
            startDate: weekAgo,
            endDate: now
        )

        XCTAssertFalse(letter.fullText.isEmpty)
        XCTAssertTrue(letter.fullText.contains("Dear Self"))
        XCTAssertTrue(letter.fullText.contains("2 daily check-ins"))
        XCTAssertTrue(letter.fullText.contains("1 reflection session"))
        XCTAssertFalse(letter.themes.isEmpty)
    }

    func testGenerateLetter_noData() {
        let now = Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!

        let letter = WeeklyLetterService.generateLetter(
            checkIns: [],
            sessions: [],
            moments: [],
            startDate: weekAgo,
            endDate: now
        )

        XCTAssertTrue(letter.fullText.contains("quieter week"))
    }

    func testGenerateLetterForLastWeek() {
        let checkIns = [CheckIn(mood: 6)]
        let letter = WeeklyLetterService.generateLetterForLastWeek(
            checkIns: checkIns,
            sessions: [],
            moments: []
        )
        XCTAssertFalse(letter.fullText.isEmpty)
    }
}

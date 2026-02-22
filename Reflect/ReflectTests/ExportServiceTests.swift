import XCTest
@testable import Reflect

final class ExportServiceTests: XCTestCase {

    // MARK: - JSON Export

    func testExportToJSON_basicStructure() throws {
        let checkIns = [
            CheckIn(mood: 7, energy: 6, stress: 3, sleepHours: 8.0, sleepQuality: 8, note: "Good day"),
        ]
        let sessions = [
            ReflectionSession(
                title: "Morning",
                captureResponse: "Birds singing",
                meaningResponse: "Joy",
                nextStepResponse: "Listen"
            ),
        ]
        let moments = [
            Moment(quote: "The sound of rain", themes: ["Nature"], emotions: ["Peace"]),
        ]
        let letters = [
            WeeklyLetter(fullText: "Dear Self..."),
        ]

        let data = try ExportService.exportToJSON(
            checkIns: checkIns, sessions: sessions,
            moments: moments, letters: letters
        )

        // Parse the JSON to verify structure
        let json = try JSONDecoder().decode(ExportService.ExportBundle.self, from: data)
        XCTAssertEqual(json.appName, "Reflect")
        XCTAssertEqual(json.checkIns.count, 1)
        XCTAssertEqual(json.reflectionSessions.count, 1)
        XCTAssertEqual(json.moments.count, 1)
        XCTAssertEqual(json.weeklyLetters.count, 1)
        XCTAssertEqual(json.checkIns.first?.mood, 7)
        XCTAssertEqual(json.reflectionSessions.first?.title, "Morning")
        XCTAssertEqual(json.moments.first?.quote, "The sound of rain")
    }

    func testExportToJSON_empty() throws {
        let data = try ExportService.exportToJSON(
            checkIns: [], sessions: [], moments: [], letters: []
        )
        let json = try JSONDecoder().decode(ExportService.ExportBundle.self, from: data)
        XCTAssertTrue(json.checkIns.isEmpty)
        XCTAssertTrue(json.reflectionSessions.isEmpty)
    }

    func testExportToJSON_isValidJSON() throws {
        let checkIns = [CheckIn(mood: 5, note: "Test \"quotes\" and special chars: <>&")]
        let data = try ExportService.exportToJSON(
            checkIns: checkIns, sessions: [], moments: [], letters: []
        )
        // Should be valid JSON (no throw)
        let obj = try JSONSerialization.jsonObject(with: data)
        XCTAssertNotNil(obj)
    }

    // MARK: - Text Export

    func testExportToText_containsHeader() {
        let text = ExportService.exportToText(
            checkIns: [], sessions: [], moments: [], letters: []
        )
        XCTAssertTrue(text.contains("REFLECT"))
        XCTAssertTrue(text.contains("Journal Export"))
    }

    func testExportToText_containsCheckIns() {
        let checkIns = [
            CheckIn(mood: 8, energy: 7, stress: 2, sleepHours: 8.5, sleepQuality: 9, note: "Great day"),
        ]
        let text = ExportService.exportToText(
            checkIns: checkIns, sessions: [], moments: [], letters: []
        )
        XCTAssertTrue(text.contains("DAILY CHECK-INS"))
        XCTAssertTrue(text.contains("Mood: 8/10"))
        XCTAssertTrue(text.contains("Great day"))
    }

    func testExportToText_containsSessions() {
        let sessions = [
            ReflectionSession(
                title: "Deep dive",
                captureResponse: "Something shifted",
                meaningResponse: "Letting go",
                nextStepResponse: "Rest"
            ),
        ]
        let text = ExportService.exportToText(
            checkIns: [], sessions: sessions, moments: [], letters: []
        )
        XCTAssertTrue(text.contains("REFLECTION SESSIONS"))
        XCTAssertTrue(text.contains("Deep dive"))
        XCTAssertTrue(text.contains("Something shifted"))
    }

    func testExportToText_containsMoments() {
        let moments = [
            Moment(quote: "Silence speaks", themes: ["Wonder"], askOfMe: "Be still"),
        ]
        let text = ExportService.exportToText(
            checkIns: [], sessions: [], moments: moments, letters: []
        )
        XCTAssertTrue(text.contains("MOMENTS"))
        XCTAssertTrue(text.contains("Silence speaks"))
    }

    // MARK: - File Writing

    func testWriteToTempFile() throws {
        let data = Data("test content".utf8)
        let url = try ExportService.writeToTempFile(data: data, filename: "test_export.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        // Clean up
        try? FileManager.default.removeItem(at: url)
    }

    func testWriteTextToTempFile() throws {
        let url = try ExportService.writeToTempFile(text: "test text", filename: "test_export.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        let content = try String(contentsOf: url)
        XCTAssertEqual(content, "test text")

        // Clean up
        try? FileManager.default.removeItem(at: url)
    }
}

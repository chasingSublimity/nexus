import XCTest

@MainActor
final class NexusWindowTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    func test_closeButton_hidesWindow() throws {
        XCTAssertTrue(app.windows.firstMatch.exists)
        app.buttons["nexus-close-button"].click()
        XCTAssertFalse(app.windows.firstMatch.exists)
    }

    func test_escapeKey_hidesWindow() throws {
        XCTAssertTrue(app.windows.firstMatch.exists)
        app.typeKey(.escape, modifierFlags: [])
        XCTAssertFalse(app.windows.firstMatch.exists)
    }

    func test_cmdW_hidesWindow() throws {
        XCTAssertTrue(app.windows.firstMatch.exists)
        app.typeKey("w", modifierFlags: .command)
        XCTAssertFalse(app.windows.firstMatch.exists)
    }
}

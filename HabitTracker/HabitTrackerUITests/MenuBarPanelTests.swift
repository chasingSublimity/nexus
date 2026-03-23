import XCTest

// NOTE: These tests cover popover content and actions using a plain window
// that hosts MenuBarPanelView directly. Testing the NSStatusItem click itself
// is not done here — the status item lives in SystemUIServer's window, which
// XCTest cannot reliably reach across macOS versions.

@MainActor
final class MenuBarPanelTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting-popover"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    func test_panelContent_isVisible() throws {
        XCTAssertTrue(app.staticTexts["[NEURAL//HABITS]"].exists)
        XCTAssertTrue(app.staticTexts["XP TODAY: +0"].exists)
        XCTAssertTrue(app.buttons["open-nexus-button"].exists)
    }

    func test_openNexusButton_showsNexusWindow() throws {
        XCTAssertEqual(app.windows.count, 1, "only the panel window should be open initially")
        app.buttons["open-nexus-button"].click()
        XCTAssertEqual(app.windows.count, 2, "NEXUS window should appear after tapping Open NEXUS")
    }
}

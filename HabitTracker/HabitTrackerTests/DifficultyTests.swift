import XCTest
@testable import HabitTracker

final class DifficultyTests: XCTestCase {
    func test_next_easy_returns_medium() {
        XCTAssertEqual(Difficulty.easy.next(), .medium)
    }

    func test_next_medium_returns_hard() {
        XCTAssertEqual(Difficulty.medium.next(), .hard)
    }

    func test_next_hard_wraps_to_easy() {
        XCTAssertEqual(Difficulty.hard.next(), .easy)
    }
}

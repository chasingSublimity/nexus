// HabitTrackerTests/LevelSystemTests.swift
import XCTest
@testable import HabitTracker

final class LevelSystemTests: XCTestCase {

    func test_level1_startsAt0XP() {
        XCTAssertEqual(LevelSystem.threshold(for: 1), 0)
    }

    func test_level2_requires100XP() {
        XCTAssertEqual(LevelSystem.threshold(for: 2), 100)
    }

    func test_level10_requires8100XP() {
        XCTAssertEqual(LevelSystem.threshold(for: 10), 8100)
    }

    func test_levelForXP_correctlyDeterminesLevel() {
        XCTAssertEqual(LevelSystem.level(for: 0), 1)
        XCTAssertEqual(LevelSystem.level(for: 99), 1)
        XCTAssertEqual(LevelSystem.level(for: 100), 2)
        XCTAssertEqual(LevelSystem.level(for: 399), 2)
        XCTAssertEqual(LevelSystem.level(for: 400), 3)
        XCTAssertEqual(LevelSystem.level(for: 8100), 10)
    }

    func test_xpToNextLevel_isCorrect() {
        // At level 1 with 50 XP, need 50 more to reach level 2 threshold of 100
        XCTAssertEqual(LevelSystem.xpToNextLevel(currentXP: 50), 50)
    }

    func test_xpToNextLevel_atExactThreshold() {
        // At level 2 (xp=100), next threshold is level 3 at 400 → need 300 more
        XCTAssertEqual(LevelSystem.xpToNextLevel(currentXP: 100), 300)
    }

    func test_xpToNextLevel_clampsNegativeInput() {
        // Negative XP treated as 0, so same as xpToNextLevel(0) = 100
        XCTAssertEqual(LevelSystem.xpToNextLevel(currentXP: -50), 100)
    }
}

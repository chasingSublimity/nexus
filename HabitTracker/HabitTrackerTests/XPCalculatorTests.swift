// HabitTrackerTests/XPCalculatorTests.swift
import XCTest
@testable import HabitTracker

final class XPCalculatorTests: XCTestCase {

    private func makeLog(difficulty: Difficulty, completed: Bool = true, value: Double? = nil, targetValue: Double? = nil) -> (HabitLog, Habit) {
        let habit = Habit(name: "Test", type: value != nil ? .quantified : .boolean, difficulty: difficulty)
        if let target = targetValue { habit.targetValue = target }
        let log = HabitLog(habit: habit, date: Date(), completed: completed, value: value)
        return (log, habit)
    }

    func test_easyBoolean_noStreak_noPerfectDay() {
        let (log, _) = makeLog(difficulty: .easy)
        let result = XPCalculator.calculate(for: log, streak: 1, siblingsCompleted: false)
        // base=10, streak_bonus=10*min(1*0.05,1.0)=0.5→rounds to 0 in integer math, ratio=1.0, perfect=0 → 10
        XCTAssertEqual(result, 10)
    }

    func test_hardBoolean_streak20_perfectDay() {
        let (log, _) = makeLog(difficulty: .hard)
        let result = XPCalculator.calculate(for: log, streak: 20, siblingsCompleted: true)
        // base=50, streak_bonus=50*min(20*0.05,1.0)=50*1.0=50, ratio=1.0, perfect=25
        // total = (50+50)*1.0 + 25 = 125
        XCTAssertEqual(result, 125)
    }

    func test_mediumQuantified_atTarget() {
        let (log, _) = makeLog(difficulty: .medium, value: 5.0, targetValue: 5.0)
        let result = XPCalculator.calculate(for: log, streak: 1, siblingsCompleted: false)
        // base=25, streak_bonus=25*0.05=1.25, ratio=1.0 → (25+1.25)*1.0=26.25 → rounds to 26
        XCTAssertEqual(result, 26)
    }

    func test_mediumQuantified_overTarget_capsAt1_2() {
        let (log, _) = makeLog(difficulty: .medium, value: 10.0, targetValue: 5.0)
        let result = XPCalculator.calculate(for: log, streak: 0, siblingsCompleted: false)
        // base=25, streak_bonus=0, ratio=min(2.0,1.2)=1.2 → 25*1.2=30
        XCTAssertEqual(result, 30)
    }

    func test_streakCap_doesNotExceed2xBase() {
        let (log, _) = makeLog(difficulty: .hard)
        let highStreak = XPCalculator.calculate(for: log, streak: 100, siblingsCompleted: false)
        let cappedStreak = XPCalculator.calculate(for: log, streak: 20, siblingsCompleted: false)
        // Both should hit the cap: (50+50)*1.0 = 100
        XCTAssertEqual(highStreak, 100)
        XCTAssertEqual(cappedStreak, 100)
    }
}

import XCTest
import SwiftData
@testable import HabitTracker

@MainActor
final class PerfectWeekTests: XCTestCase {

    private var store: HabitStore!

    override func setUp() async throws {
        store = try HabitStore(inMemory: true)
    }

    override func tearDown() async throws {
        store = nil
    }

    func test_perfectWeek_allDaysCompleted_returnsTrue() async throws {
        let habit = try store.addHabit(name: "Test", difficulty: .easy)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let logs = (0..<7).map { offset in
            HabitLog(habit: habit, date: calendar.date(byAdding: .day, value: -offset, to: today)!, completed: true)
        }
        XCTAssertTrue(isPerfectWeek(allHabitLogs: logs, today: today))
    }

    func test_perfectWeek_missingOneDay_returnsFalse() async throws {
        let habit = try store.addHabit(name: "Test", difficulty: .easy)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        // Only 6 of 7 days (skip day index 3)
        let logs = (0..<7).compactMap { offset -> HabitLog? in
            guard offset != 3 else { return nil }
            return HabitLog(habit: habit, date: calendar.date(byAdding: .day, value: -offset, to: today)!, completed: true)
        }
        XCTAssertFalse(isPerfectWeek(allHabitLogs: logs, today: today))
    }

    func test_perfectWeek_incompleteLogDoesNotCount() async throws {
        let habit = try store.addHabit(name: "Test", difficulty: .easy)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let logs = (0..<7).map { offset in
            let completed = offset != 2  // day 2 logged but not completed
            return HabitLog(habit: habit, date: calendar.date(byAdding: .day, value: -offset, to: today)!, completed: completed)
        }
        XCTAssertFalse(isPerfectWeek(allHabitLogs: logs, today: today))
    }

    func test_perfectWeek_emptyLogs_returnsFalse() async throws {
        XCTAssertFalse(isPerfectWeek(allHabitLogs: [], today: Date()))
    }
}

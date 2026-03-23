import XCTest
import SwiftData
@testable import HabitTracker

@MainActor
final class HabitStoreTests: XCTestCase {
    var store: HabitStore!

    override func setUp() async throws {
        store = try HabitStore(inMemory: true)
    }

    override func tearDown() async throws {
        store = nil
    }

    func test_addHabit_persistsAndReturns() throws {
        _ = try store.addHabit(name: "Meditate", type: .boolean, difficulty: .medium)
        let habits = try store.fetchActiveHabits()
        XCTAssertEqual(habits.count, 1)
        XCTAssertEqual(habits[0].name, "Meditate")
        XCTAssertFalse(habits[0].isArchived)
    }

    func test_logHabit_createsHabitLog() throws {
        let habit = try store.addHabit(name: "Run", type: .quantified, difficulty: .hard)
        let log = try store.logHabit(habit, date: Date(), value: 5.0)
        XCTAssertEqual(log.value, 5.0)
        XCTAssertEqual(log.habit?.id, habit.id)
    }

    func test_archiveHabit_excludesFromActiveList() throws {
        let habit = try store.addHabit(name: "Read", type: .boolean, difficulty: .easy)
        try store.archiveHabit(habit)
        let active = try store.fetchActiveHabits()
        XCTAssertTrue(active.isEmpty)
    }

    func test_fetchOrCreateProfile_returnsSingleton() throws {
        let p1 = try store.fetchOrCreateProfile()
        let p2 = try store.fetchOrCreateProfile()
        XCTAssertEqual(p1.persistentModelID, p2.persistentModelID)
    }

    func test_fetchLogs_returnsLogsInRange() throws {
        let habit = try store.addHabit(name: "Run", type: .quantified, difficulty: .hard)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let lastWeek = calendar.date(byAdding: .day, value: -7, to: today)!

        _ = try store.logHabit(habit, date: today, value: 3.0)
        _ = try store.logHabit(habit, date: yesterday, value: 2.0)
        _ = try store.logHabit(habit, date: lastWeek, value: 1.0)

        let range = yesterday...today
        let logs = try store.fetchLogs(for: habit, in: range)
        XCTAssertEqual(logs.count, 2)
    }

    func test_logHabit_replacesExistingLogForSameDay() throws {
        let habit = try store.addHabit(name: "Read", type: .quantified, difficulty: .easy)
        let date = Date()
        _ = try store.logHabit(habit, date: date, value: 10.0)
        _ = try store.logHabit(habit, date: date, value: 20.0)
        let logs = try store.fetchLogs(for: habit, in: date...date)
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs[0].value, 20.0)
    }
}

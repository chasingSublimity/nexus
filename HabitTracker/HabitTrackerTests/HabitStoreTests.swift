import XCTest
import SwiftData
@testable import HabitTracker

final class HabitStoreTests: XCTestCase {
    var store: HabitStore!

    override func setUp() async throws {
        store = try HabitStore(inMemory: true)
    }

    func test_addHabit_persistsAndReturns() throws {
        let habit = try store.addHabit(name: "Meditate", type: .boolean, difficulty: .medium)
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
}

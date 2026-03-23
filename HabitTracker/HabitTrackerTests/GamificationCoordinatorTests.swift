import XCTest
import SwiftData
@testable import HabitTracker

@MainActor
final class GamificationCoordinatorTests: XCTestCase {

    private var store: HabitStore!
    private var coordinator: GamificationCoordinator!

    override func setUp() async throws {
        store = try HabitStore(inMemory: true)
        coordinator = GamificationCoordinator(store: store)
    }

    override func tearDown() async throws {
        coordinator = nil
        store = nil
    }

    // MARK: - XP Pipeline

    func test_logAndProcess_awardsXP() async throws {
        let habit = try store.addHabit(name: "Test", difficulty: .easy)
        coordinator.logAndProcess(habit: habit, date: Date(), completed: true)
        XCTAssertGreaterThan(coordinator.todayXP, 0)
    }

    func test_logAndProcess_updatesProfileXPAndCompletionCount() async throws {
        let habit = try store.addHabit(name: "Test", difficulty: .easy)
        coordinator.logAndProcess(habit: habit, date: Date(), completed: true)
        let profile = try store.fetchOrCreateProfile()
        XCTAssertGreaterThan(profile.xp, 0)
        XCTAssertEqual(profile.totalHabitsCompleted, 1)
    }

    func test_logAndProcess_syncsLevel() async throws {
        // Two hard habits completed → enough XP to cross level 2 threshold (100)
        let h1 = try store.addHabit(name: "A", difficulty: .hard)
        let h2 = try store.addHabit(name: "B", difficulty: .hard)
        coordinator.logAndProcess(habit: h1, date: Date(), completed: true)
        coordinator.logAndProcess(habit: h2, date: Date(), completed: true)
        let profile = try store.fetchOrCreateProfile()
        XCTAssertGreaterThanOrEqual(profile.level, 2)
    }

    func test_logAndProcess_doesNotAwardXPWhenNotCompleted() async throws {
        let habit = try store.addHabit(name: "Test", difficulty: .easy)
        coordinator.logAndProcess(habit: habit, date: Date(), completed: false)
        XCTAssertEqual(coordinator.todayXP, 0)
        let profile = try store.fetchOrCreateProfile()
        XCTAssertEqual(profile.xp, 0)
        XCTAssertEqual(profile.totalHabitsCompleted, 0)
    }

    func test_logAndProcess_accumulatesXPAcrossHabits() async throws {
        let h1 = try store.addHabit(name: "A", difficulty: .easy)
        let h2 = try store.addHabit(name: "B", difficulty: .easy)
        coordinator.logAndProcess(habit: h1, date: Date(), completed: true)
        let firstXP = coordinator.todayXP
        coordinator.logAndProcess(habit: h2, date: Date(), completed: true)
        XCTAssertGreaterThan(coordinator.todayXP, firstXP)
    }

    // MARK: - Activity Log

    func test_logAndProcess_appendsXPEntryToActivityLog() async throws {
        let habit = try store.addHabit(name: "Exercise", difficulty: .medium)
        let countBefore = coordinator.activityLog.count
        coordinator.logAndProcess(habit: habit, date: Date(), completed: true)
        XCTAssertGreaterThan(coordinator.activityLog.count, countBefore)
        let lastEntry = coordinator.activityLog.last!
        XCTAssertTrue(lastEntry.contains("EXERCISE"))
        XCTAssertTrue(lastEntry.contains("XP"))
    }

    func test_logAndProcess_revertAppendsRevertedEntry() async throws {
        let habit = try store.addHabit(name: "Exercise", difficulty: .medium)
        coordinator.logAndProcess(habit: habit, date: Date(), completed: false)
        let lastEntry = coordinator.activityLog.last!
        XCTAssertTrue(lastEntry.contains("REVERTED"))
        XCTAssertTrue(lastEntry.contains("EXERCISE"))
    }

    // MARK: - Achievements

    func test_logAndProcess_unlocksStreak7Achievement() async throws {
        let habit = try store.addHabit(name: "Test", difficulty: .easy)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        // Pre-seed 6 consecutive days
        for dayOffset in (1...6).reversed() {
            let d = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            _ = try store.logHabit(habit, date: d, completed: true)
        }
        // 7th day via coordinator
        coordinator.logAndProcess(habit: habit, date: today, completed: true)
        let profile = try store.fetchOrCreateProfile()
        XCTAssertTrue(profile.achievements.contains { $0.key == "streak_7" })
    }

    func test_logAndProcess_logsAchievementUnlockToActivityLog() async throws {
        let habit = try store.addHabit(name: "Test", difficulty: .easy)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        for dayOffset in (1...6).reversed() {
            let d = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            _ = try store.logHabit(habit, date: d, completed: true)
        }
        coordinator.logAndProcess(habit: habit, date: today, completed: true)
        XCTAssertTrue(coordinator.activityLog.contains { $0.contains("ACHIEVEMENT UNLOCKED") })
    }
}

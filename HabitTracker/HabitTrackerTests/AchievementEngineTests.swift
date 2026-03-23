// HabitTrackerTests/AchievementEngineTests.swift
import XCTest
import SwiftData
@testable import HabitTracker

@MainActor
final class AchievementEngineTests: XCTestCase {

    private var store: HabitStore!

    override func setUp() async throws {
        store = try HabitStore(inMemory: true)
    }

    override func tearDown() async throws {
        store = nil
    }

    private func makeEngine() -> AchievementEngine {
        AchievementEngine()
    }

    private func consecutiveLogs(habit: Habit, days: Int, endingOn date: Date) -> [HabitLog] {
        (0..<days).map { offset in
            let d = Calendar.current.date(byAdding: .day, value: -(days - 1 - offset), to: date)!
            return HabitLog(habit: habit, date: d, completed: true)
        }
    }

    func test_streak7_unlocks() async throws {
        let engine = makeEngine()
        let habit = try store.addHabit(name: "Test", type: .boolean, difficulty: .easy)
        let profile = try store.fetchOrCreateProfile()
        let today = Date()
        let logs = consecutiveLogs(habit: habit, days: 7, endingOn: today)

        let unlocked = engine.evaluate(habit: habit, allLogs: logs, profile: profile, today: today)
        XCTAssertTrue(unlocked.contains("streak_7"))
    }

    func test_streak7_doesNotUnlock_with6Days() async throws {
        let engine = makeEngine()
        let habit = try store.addHabit(name: "Test", type: .boolean, difficulty: .easy)
        let profile = try store.fetchOrCreateProfile()
        let today = Date()
        let logs = consecutiveLogs(habit: habit, days: 6, endingOn: today)
        let unlocked = engine.evaluate(habit: habit, allLogs: logs, profile: profile, today: today)
        XCTAssertFalse(unlocked.contains("streak_7"))
    }

    func test_comebackKid_unlocks_after7DayGap() async throws {
        let engine = makeEngine()
        let habit = try store.addHabit(name: "Test", type: .boolean, difficulty: .easy)
        let profile = try store.fetchOrCreateProfile()
        let calendar = Calendar.current
        let todayNorm = calendar.startOfDay(for: Date())
        let yesterday  = calendar.date(byAdding: .day, value: -1, to: todayNorm)!
        let eightAgo   = calendar.date(byAdding: .day, value: -8, to: todayNorm)!
        // gap from eightAgo → yesterday = 7 days ✓; twoDaysAgo absent ✓
        let logs = [
            HabitLog(habit: habit, date: todayNorm,  completed: true),
            HabitLog(habit: habit, date: yesterday,  completed: true),
            HabitLog(habit: habit, date: eightAgo,   completed: true),
        ]
        let unlocked = engine.evaluate(habit: habit, allLogs: logs, profile: profile, today: todayNorm)
        XCTAssertTrue(unlocked.contains("comeback_kid"))
    }

    func test_comebackKid_doesNotUnlock_with6DayGap() async throws {
        let engine = makeEngine()
        let habit = try store.addHabit(name: "Test", type: .boolean, difficulty: .easy)
        let profile = try store.fetchOrCreateProfile()
        let calendar = Calendar.current
        let todayNorm = calendar.startOfDay(for: Date())
        let yesterday  = calendar.date(byAdding: .day, value: -1, to: todayNorm)!
        let sevenAgo   = calendar.date(byAdding: .day, value: -7, to: todayNorm)!
        // gap from sevenAgo → yesterday = 6 days (one below the 7-day threshold)
        let logs = [
            HabitLog(habit: habit, date: todayNorm,  completed: true),
            HabitLog(habit: habit, date: yesterday,  completed: true),
            HabitLog(habit: habit, date: sevenAgo,   completed: true),
        ]
        let unlocked = engine.evaluate(habit: habit, allLogs: logs, profile: profile, today: todayNorm)
        XCTAssertFalse(unlocked.contains("comeback_kid"))
    }

    func test_comebackKid_doesNotUnlock_withSmallGap() async throws {
        let engine = makeEngine()
        let habit = try store.addHabit(name: "Test", type: .boolean, difficulty: .easy)
        let profile = try store.fetchOrCreateProfile()
        let calendar = Calendar.current
        let todayNorm = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: todayNorm)!
        let fourAgo   = calendar.date(byAdding: .day, value: -4, to: todayNorm)!
        // gap from fourAgo → yesterday = 3 days < 7 ✗
        let logs = [
            HabitLog(habit: habit, date: todayNorm, completed: true),
            HabitLog(habit: habit, date: yesterday, completed: true),
            HabitLog(habit: habit, date: fourAgo,   completed: true),
        ]
        let unlocked = engine.evaluate(habit: habit, allLogs: logs, profile: profile, today: todayNorm)
        XCTAssertFalse(unlocked.contains("comeback_kid"))
    }

    func test_nightOwl_unlocks_after5LateNights() async throws {
        let engine = makeEngine()
        let habit = try store.addHabit(name: "Test", type: .boolean, difficulty: .easy)
        let profile = try store.fetchOrCreateProfile()
        let calendar = Calendar.current
        // Build 5 logs each timestamped at 23:00 on successive past days.
        // HabitLog.init sets loggedAt = date (raw), so hour is preserved.
        let lateLogs: [HabitLog] = (0..<5).map { offset in
            var comps = calendar.dateComponents([.year, .month, .day], from: Date())
            comps.hour = 23; comps.minute = 0; comps.second = 0
            let base = calendar.date(from: comps)!
            let d = calendar.date(byAdding: .day, value: -offset, to: base)!
            return HabitLog(habit: habit, date: d, completed: true)
        }
        let unlocked = engine.evaluate(habit: habit, allLogs: lateLogs, profile: profile, today: Date())
        XCTAssertTrue(unlocked.contains("night_owl"))
    }

    func test_alreadyUnlocked_notReturnedAgain() async throws {
        let engine = makeEngine()
        let habit = try store.addHabit(name: "Test", type: .boolean, difficulty: .easy)
        let profile = try store.fetchOrCreateProfile()
        // Pre-seed the profile with streak_7 already unlocked
        let achievement = Achievement(key: "streak_7")
        store.container.mainContext.insert(achievement)
        achievement.profile = profile
        profile.achievements.append(achievement)

        let today = Date()
        let logs = consecutiveLogs(habit: habit, days: 7, endingOn: today)
        let unlocked = engine.evaluate(habit: habit, allLogs: logs, profile: profile, today: today)
        XCTAssertFalse(unlocked.contains("streak_7"))
    }
}

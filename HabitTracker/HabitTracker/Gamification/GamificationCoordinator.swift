import Combine
import Foundation
import SwiftData

@MainActor
final class GamificationCoordinator: ObservableObject {
    @Published private(set) var todayXP: Int = 0

    private let store: HabitStore
    private let engine = AchievementEngine()

    var container: ModelContainer { store.container }

    init(store: HabitStore) {
        self.store = store
    }

    /// Writes a habit log and runs the XP + achievement pipeline.
    /// Passing `completed: false` uncompletes the habit without awarding XP.
    func logAndProcess(habit: Habit, date: Date, completed: Bool, value: Double? = nil) {
        guard let log = try? store.logHabit(habit, date: date, completed: completed, value: value) else { return }
        guard completed else { return }
        guard let profile = try? store.fetchOrCreateProfile() else { return }

        let allHabitLogs = habit.logs
        let streak = currentStreak(in: allHabitLogs, asOf: date)

        let activeHabits = (try? store.fetchActiveHabits()) ?? []
        let siblingsCompleted = activeHabits
            .filter { $0.id != habit.id }
            .allSatisfy { sibling in
                sibling.logs.contains { Calendar.current.isDateInToday($0.date) && $0.completed }
            }

        let xpGained = XPCalculator.calculate(for: log, streak: streak, siblingsCompleted: siblingsCompleted)
        profile.xp += xpGained
        profile.totalHabitsCompleted += 1
        profile.level = LevelSystem.level(for: profile.xp)
        todayXP += xpGained

        var newKeys = engine.evaluate(habit: habit, allLogs: allHabitLogs, profile: profile, today: date)

        let alreadyUnlocked = Set(profile.achievements.map(\.key))
        if !alreadyUnlocked.contains("perfect_week") {
            let combinedLogs = activeHabits.flatMap { $0.logs }
            if isPerfectWeek(allHabitLogs: combinedLogs, today: date) {
                newKeys.append("perfect_week")
            }
        }

        for key in newKeys {
            let achievement = Achievement(key: key)
            store.container.mainContext.insert(achievement)
            profile.achievements.append(achievement)
        }

        try? store.container.mainContext.save()
    }

    private func currentStreak(in logs: [HabitLog], asOf today: Date) -> Int {
        let calendar = Calendar.current
        let todayNorm = calendar.startOfDay(for: today)
        let completedDays = Set(logs.filter { $0.completed }.map { calendar.startOfDay(for: $0.date) })
        var streak = 0
        var day = todayNorm
        while completedDays.contains(day) {
            streak += 1
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        return streak
    }
}

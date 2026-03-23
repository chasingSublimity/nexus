import Foundation

@MainActor
final class AchievementEngine {

    /// Evaluates which new achievements should unlock after a log write.
    /// Returns keys of newly-unlocked achievements (not already in profile).
    func evaluate(habit: Habit, allLogs: [HabitLog], profile: UserProfile, today: Date) -> [String] {
        let alreadyUnlocked = Set(profile.achievements.map(\.key))
        var newKeys: [String] = []

        func check(_ key: String, condition: () -> Bool) {
            if !alreadyUnlocked.contains(key) && condition() {
                newKeys.append(key)
            }
        }

        let streak = currentStreak(in: allLogs, asOf: today)

        check("streak_7")     { streak >= 7 }
        check("streak_30")    { streak >= 30 }
        check("comeback_kid") { isComebackKid(logs: allLogs, today: today) }
        check("night_owl")    { nightOwlCount(logs: allLogs) >= 5 }
        check("centurion")    { profile.totalHabitsCompleted >= 100 }
        // NOTE: perfect_week is NOT evaluated here — it requires all habits' combined logs.
        // GamificationCoordinator.processLog() evaluates it separately with the full log set.

        // level achievements use current profile state
        check("level_10") { profile.level >= 10 }

        return newKeys
    }

    // MARK: - Private helpers

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

    private func isComebackKid(logs: [HabitLog], today: Date) -> Bool {
        let calendar = Calendar.current
        let todayNorm = calendar.startOfDay(for: today)
        let yesterdayNorm = calendar.date(byAdding: .day, value: -1, to: todayNorm)!

        let completedDays = Set(logs.filter { $0.completed }.map { calendar.startOfDay(for: $0.date) })

        // Must have completed today and yesterday (2-day streak)
        guard completedDays.contains(todayNorm), completedDays.contains(yesterdayNorm) else { return false }
        // Must NOT have completed the day before yesterday (streak is exactly starting)
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: todayNorm)!
        guard !completedDays.contains(twoDaysAgo) else { return false }
        // Gap before the streak must be 7+ days
        let sortedDays = completedDays.sorted()
        guard let lastBeforeGap = sortedDays.last(where: { $0 < yesterdayNorm }) else { return false }
        let gap = calendar.dateComponents([.day], from: lastBeforeGap, to: yesterdayNorm).day ?? 0
        return gap >= 7
    }

    private func nightOwlCount(logs: [HabitLog]) -> Int {
        // night_owl: use loggedAt (raw timestamp) not date (normalized to midnight)
        logs.filter { log in
            let hour = Calendar.current.component(.hour, from: log.loggedAt)
            return hour >= 23
        }.count
    }
}

// MARK: - Perfect Week helper (used by GamificationCoordinator, not AchievementEngine)
/// Returns true if all logs show completion for every one of the last 7 days.
/// Must be called with the combined logs of ALL active habits, not a single habit's logs.
func isPerfectWeek(allHabitLogs: [HabitLog], today: Date) -> Bool {
    let calendar = Calendar.current
    let last7Days = (0..<7).map { calendar.date(byAdding: .day, value: -$0, to: calendar.startOfDay(for: today))! }
    let completedDays = Set(allHabitLogs.filter { $0.completed }.map { calendar.startOfDay(for: $0.date) })
    return last7Days.allSatisfy { completedDays.contains($0) }
}

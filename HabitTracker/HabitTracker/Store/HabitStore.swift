import Foundation
import SwiftData

@MainActor
final class HabitStore {
    let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    init(inMemory: Bool = false) throws {
        let schema = Schema([Habit.self, HabitLog.self, UserProfile.self, Achievement.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        container = try ModelContainer(for: schema, configurations: [config])
    }

    // MARK: - Habits

    func addHabit(
        name: String,
        type: HabitType = .boolean,
        difficulty: Difficulty = .medium,
        color: String = "#39FF14",
        icon: String = "circle.fill"
    ) throws -> Habit {
        let habits = try fetchActiveHabits()
        let habit = Habit(
            name: name,
            type: type,
            difficulty: difficulty,
            color: color,
            icon: icon,
            sortOrder: habits.count
        )
        context.insert(habit)
        try context.save()
        return habit
    }

    func fetchActiveHabits() throws -> [Habit] {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return try context.fetch(descriptor)
    }

    func archiveHabit(_ habit: Habit) throws {
        habit.isArchived = true
        try context.save()
    }

    // MARK: - Logs

    func logHabit(_ habit: Habit, date: Date, completed: Bool = true, value: Double? = nil) throws -> HabitLog {
        let normalized = Calendar.current.startOfDay(for: date)
        // Remove existing log for this day if present
        let existing = habit.logs.first {
            Calendar.current.isDate($0.date, inSameDayAs: normalized)
        }
        if let existing { context.delete(existing) }

        let log = HabitLog(habit: habit, date: normalized, completed: completed, value: value)
        context.insert(log)
        try context.save()
        return log
    }

    func fetchLogs(for habit: Habit, in range: ClosedRange<Date>) throws -> [HabitLog] {
        let start = Calendar.current.startOfDay(for: range.lowerBound)
        let end = Calendar.current.startOfDay(for: range.upperBound)
        let habitID = habit.id
        let descriptor = FetchDescriptor<HabitLog>(
            predicate: #Predicate { log in
                log.habit?.id == habitID && log.date >= start && log.date <= end
            },
            sortBy: [SortDescriptor(\.date)]
        )
        return try context.fetch(descriptor)
    }

    // MARK: - Profile

    func fetchOrCreateProfile() throws -> UserProfile {
        let descriptor = FetchDescriptor<UserProfile>()
        let existing = try context.fetch(descriptor)
        if let profile = existing.first { return profile }
        let profile = UserProfile()
        context.insert(profile)
        try context.save()
        return profile
    }
}

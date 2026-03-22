import Foundation
import SwiftData

@Model
final class HabitLog {
    var id: UUID
    var date: Date           // normalized to midnight — used for "did user log today?" queries
    var loggedAt: Date       // raw timestamp — used for time-of-day features (night_owl achievement)
    var completed: Bool
    var value: Double?
    var habit: Habit?

    init(habit: Habit, date: Date, completed: Bool = true, value: Double? = nil) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.loggedAt = date   // preserve raw timestamp
        self.completed = completed
        self.value = value
        self.habit = habit
    }
}

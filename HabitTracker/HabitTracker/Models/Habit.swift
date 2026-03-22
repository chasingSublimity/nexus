import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID
    var name: String
    var type: HabitType
    var unit: String?
    var targetValue: Double?
    var difficulty: Difficulty
    var notificationHour: Int?    // DateComponents.hour
    var notificationMinute: Int?  // DateComponents.minute
    var color: String             // hex string
    var icon: String              // SF Symbol name
    var sortOrder: Int
    var isArchived: Bool

    @Relationship(deleteRule: .cascade, inverse: \HabitLog.habit)
    var logs: [HabitLog] = []

    init(
        name: String,
        type: HabitType = .boolean,
        difficulty: Difficulty = .medium,
        color: String = "#39FF14",
        icon: String = "circle.fill",
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.difficulty = difficulty
        self.color = color
        self.icon = icon
        self.sortOrder = sortOrder
        self.isArchived = false
    }

    var notificationTime: DateComponents? {
        guard let hour = notificationHour, let minute = notificationMinute else { return nil }
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return components
    }
}

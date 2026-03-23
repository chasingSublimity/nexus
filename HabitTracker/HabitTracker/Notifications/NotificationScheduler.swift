import Foundation
import UserNotifications

// Protocol for testability
protocol UserNotificationCenter {
    func add(_ request: UNNotificationRequest) async throws
    func removeAllPendingNotificationRequests()
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
}

extension UNUserNotificationCenter: UserNotificationCenter {}

final class NotificationScheduler {
    private let center: any UserNotificationCenter

    init(center: any UserNotificationCenter = UNUserNotificationCenter.current()) {
        self.center = center
    }

    func requestPermission() async {
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    /// Removes all existing habit notifications and schedules fresh ones.
    func rebuild(for habits: [Habit]) async throws {
        center.removeAllPendingNotificationRequests()

        for habit in habits where !habit.isArchived {
            guard let hour = habit.notificationHour,
                  let minute = habit.notificationMinute else { continue }

            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute

            let content = UNMutableNotificationContent()
            content.title = "NEURAL//HABITS"
            content.body = "TIME TO LOG: \(habit.name.uppercased())"
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "habit-\(habit.id.uuidString)",
                content: content,
                trigger: trigger
            )
            try await center.add(request)
        }
    }
}

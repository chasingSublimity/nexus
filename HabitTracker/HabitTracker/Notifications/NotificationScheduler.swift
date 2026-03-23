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

    /// Requests notification authorization. Returns whether permission was granted.
    @discardableResult
    func requestPermission() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    /// Removes all existing habit notifications and schedules fresh ones.
    /// Scheduling individual habits is best-effort — a single failure does not abort remaining habits.
    func rebuild(for habits: [Habit]) async {
        center.removeAllPendingNotificationRequests()

        for habit in habits where !habit.isArchived {
            guard let dateComponents = habit.notificationTime else { continue }

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
            try? await center.add(request)
        }
    }
}

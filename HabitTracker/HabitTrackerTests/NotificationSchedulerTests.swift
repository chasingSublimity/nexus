import XCTest
import UserNotifications
@testable import HabitTracker

final class NotificationSchedulerTests: XCTestCase {

    func test_scheduleHabits_requestsCorrectNotificationCount() async throws {
        let center = MockNotificationCenter()
        let scheduler = await NotificationScheduler(center: center)

        let habit1 = Habit(name: "Meditate", difficulty: .easy)
        habit1.notificationHour = 8
        habit1.notificationMinute = 0

        let habit2 = Habit(name: "Run", difficulty: .hard)
        habit2.notificationHour = 18
        habit2.notificationMinute = 30

        let habit3 = Habit(name: "Read", difficulty: .medium)
        // no notification time set

        await scheduler.rebuild(for: [habit1, habit2, habit3])

        XCTAssertEqual(center.pendingRequests.count, 2)
    }

    func test_rebuild_removesOldNotificationsFirst() async throws {
        let center = MockNotificationCenter()
        let scheduler = await NotificationScheduler(center: center)

        let habit = Habit(name: "Meditate", difficulty: .easy)
        habit.notificationHour = 8
        habit.notificationMinute = 0

        await scheduler.rebuild(for: [habit])
        await scheduler.rebuild(for: [habit])

        // Should still only have 1, not 2 (old ones removed before re-adding)
        XCTAssertEqual(center.pendingRequests.count, 1)
        XCTAssertTrue(center.removeAllCalled)
    }
}

// MARK: - Mock
final class MockNotificationCenter: UserNotificationCenter {
    var pendingRequests: [UNNotificationRequest] = []
    var removeAllCalled = false

    func add(_ request: UNNotificationRequest) async throws {
        pendingRequests.append(request)
    }

    func removeAllPendingNotificationRequests() {
        removeAllCalled = true
        pendingRequests.removeAll()
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { true }
}

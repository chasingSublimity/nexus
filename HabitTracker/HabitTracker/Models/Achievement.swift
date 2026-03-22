import Foundation
import SwiftData

@Model
final class Achievement {
    var id: UUID
    var key: String        // e.g. "streak_7", "comeback_kid"
    var unlockedAt: Date
    var profile: UserProfile?

    init(key: String, unlockedAt: Date = Date()) {
        self.id = UUID()
        self.key = key
        self.unlockedAt = unlockedAt
    }
}

import Foundation
import SwiftData

@Model
final class UserProfile {
    var xp: Int
    var level: Int
    var totalHabitsCompleted: Int  // sole writer: AchievementEngine
    var reduceMotion: Bool

    @Relationship(deleteRule: .cascade, inverse: \Achievement.profile)
    var achievements: [Achievement] = []

    init() {
        self.xp = 0
        self.level = 1
        self.totalHabitsCompleted = 0
        self.reduceMotion = false
    }
}

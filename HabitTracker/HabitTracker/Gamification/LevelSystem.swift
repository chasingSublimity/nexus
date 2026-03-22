// HabitTracker/Gamification/LevelSystem.swift
import Foundation

enum LevelSystem {
    /// XP required to reach level n. Formula: 100 × (n-1)²
    static func threshold(for level: Int) -> Int {
        guard level >= 1 else { return 0 }
        let n = level - 1
        return 100 * n * n
    }

    /// Determines the current level for a given total XP.
    static func level(for xp: Int) -> Int {
        var level = 1
        while threshold(for: level + 1) <= xp {
            level += 1
        }
        return level
    }

    /// XP needed to reach the next level from the current total.
    static func xpToNextLevel(currentXP: Int) -> Int {
        let current = level(for: currentXP)
        return threshold(for: current + 1) - currentXP
    }
}

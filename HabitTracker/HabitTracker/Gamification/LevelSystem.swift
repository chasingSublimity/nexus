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
        guard xp >= 0 else { return 1 }
        return Int(sqrt(Double(xp) / 100.0)) + 1
    }

    /// XP needed to reach the next level from the current total.
    static func xpToNextLevel(currentXP: Int) -> Int {
        let xp = max(0, currentXP)
        let current = level(for: xp)
        return threshold(for: current + 1) - xp
    }
}

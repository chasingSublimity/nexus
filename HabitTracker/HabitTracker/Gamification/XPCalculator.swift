// HabitTracker/Gamification/XPCalculator.swift
import Foundation

enum XPCalculator {
    static func calculate(for log: HabitLog, streak: Int, siblingsCompleted: Bool) -> Int {
        guard let habit = log.habit else { return 0 }

        let base = Double(habit.difficulty.xp)
        let streakMultiplier = min(Double(streak) * 0.05, 1.0)
        let streakBonus = Double(Int(base * streakMultiplier))

        let ratioMultiplier: Double
        if habit.type == .quantified,
           let value = log.value,
           let target = habit.targetValue,
           target > 0 {
            ratioMultiplier = min(value / target, 1.2)
        } else {
            ratioMultiplier = 1.0
        }

        let perfectDayBonus: Double = siblingsCompleted ? 25 : 0
        let total = (base + streakBonus) * ratioMultiplier + perfectDayBonus
        return Int(total.rounded())
    }
}

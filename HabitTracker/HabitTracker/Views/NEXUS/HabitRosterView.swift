import SwiftUI
import SwiftData

struct HabitRosterView: View {
    @Query(filter: #Predicate<Habit> { !$0.isArchived },
           sort: \Habit.sortOrder) private var habits: [Habit]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                sectionHeader("HABIT ROSTER")

                if habits.isEmpty {
                    Text("NO HABITS\nLOADED")
                        .font(.firaCode(11))
                        .foregroundColor(.white.opacity(0.3))
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    ForEach(habits) { habit in
                        habitRow(habit)
                        Divider().background(Color.white.opacity(0.05))
                    }
                }
            }
        }
        .background(Color.darkNavy)
    }

    private func habitRow(_ habit: Habit) -> some View {
        let todayLog = habit.logs.first {
            Calendar.current.isDateInToday($0.date)
        }
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: habit.color).opacity(todayLog?.completed == true ? 1 : 0.2))
                    .frame(width: 6, height: 6)
                Text("▸ \(habit.name.uppercased())")
                    .font(.firaCode(11, weight: .medium))
                    .foregroundColor(todayLog?.completed == true ? Color(hex: habit.color) : .white.opacity(0.8))
                    .lineLimit(1)
            }
            streakBar(for: habit)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func streakBar(for habit: Habit) -> some View {
        let streak = currentStreak(for: habit)
        let maxDisplay = 7
        let filled = min(streak, maxDisplay)
        let blocks = String(repeating: "█", count: filled) + String(repeating: "░", count: maxDisplay - filled)
        return Text(blocks + " \(streak)d")
            .font(.firaCode(9))
            .foregroundColor(Color(hex: habit.color).opacity(0.6))
    }

    private func currentStreak(for habit: Habit) -> Int {
        var streak = 0
        var day = Calendar.current.startOfDay(for: Date())
        let completedDays = Set(habit.logs.filter { $0.completed }.map {
            Calendar.current.startOfDay(for: $0.date)
        })
        while completedDays.contains(day) {
            streak += 1
            day = Calendar.current.date(byAdding: .day, value: -1, to: day)!
        }
        return streak
    }

    private func sectionHeader(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.firaCode(10, weight: .bold))
                .foregroundColor(.neonGreen.opacity(0.6))
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.voidBlack)
    }
}

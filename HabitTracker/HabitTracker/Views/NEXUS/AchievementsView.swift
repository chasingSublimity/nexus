import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Query private var profiles: [UserProfile]
    private var profile: UserProfile? { profiles.first }

    private let allAchievements: [(key: String, description: String)] = [
        ("streak_7",      "7 CONSECUTIVE DAYS ON ANY HABIT"),
        ("streak_30",     "30 CONSECUTIVE DAYS ON ANY HABIT"),
        ("level_10",      "REACH LEVEL 10"),
        ("night_owl",     "LOG A HABIT AFTER 23:00 ON 5 NIGHTS"),
        ("centurion",     "100 TOTAL HABIT COMPLETIONS"),
        ("perfect_week",  "ALL HABITS COMPLETE EVERY DAY FOR 7 DAYS"),
        ("comeback_kid",  "2-DAY STREAK AFTER 7+ DAYS ABSENCE"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                sectionHeader("ACHIEVEMENTS")

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 12) {
                    ForEach(allAchievements, id: \.key) { achievement in
                        achievementCard(achievement, profile: profile)
                    }
                }
                .padding(12)
            }
        }
        .background(Color.darkNavy)
    }

    private func achievementCard(_ achievement: (key: String, description: String), profile: UserProfile?) -> some View {
        let unlocked = profile?.achievements.contains { $0.key == achievement.key } == true
        let unlockedDate = profile?.achievements.first { $0.key == achievement.key }?.unlockedAt

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(unlocked ? "◈" : "░")
                    .font(.firaCode(18, weight: .bold))
                    .foregroundColor(unlocked ? .neonGreen : .white.opacity(0.15))
                Spacer()
                if unlocked {
                    Text("UNLOCKED")
                        .font(.firaCode(8))
                        .foregroundColor(.neonGreen.opacity(0.6))
                }
            }

            Text(achievement.key.uppercased().replacingOccurrences(of: "_", with: " "))
                .font(.firaCode(12, weight: .bold))
                .foregroundColor(unlocked ? .white : .white.opacity(0.2))

            Text(achievement.description)
                .font(.firaCode(9))
                .foregroundColor(unlocked ? .white.opacity(0.5) : .white.opacity(0.1))
                .lineLimit(2)

            if let date = unlockedDate {
                Text(date, style: .date)
                    .font(.firaCode(8))
                    .foregroundColor(.neonBlue.opacity(0.5))
            }
        }
        .padding(12)
        .background(unlocked ? Color.dimGray : Color.voidBlack)
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(unlocked ? Color.neonGreen.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)
        )
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

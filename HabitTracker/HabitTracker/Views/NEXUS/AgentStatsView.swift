import SwiftUI
import SwiftData

struct AgentStatsView: View {
    @Query private var profiles: [UserProfile]
    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                sectionHeader("AGENT STATS")

                if let profile {
                    statsContent(profile)
                } else {
                    Text("LOADING...")
                        .font(.firaCode(10))
                        .foregroundColor(.white.opacity(0.3))
                        .padding()
                }
            }
        }
        .background(Color.darkNavy)
    }

    private func statsContent(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("LVL \(profile.level)")
                    .font(.firaCode(20, weight: .bold))
                    .foregroundColor(.neonGreen)
                Text("XP: \(profile.xp)")
                    .font(.firaCode(11))
                    .foregroundColor(.neonBlue)
                xpBar(profile)
            }
            .padding(.horizontal, 12)

            Divider().background(Color.neonGreen.opacity(0.15))

            sectionHeader("ACHIEVEMENTS")
            achievementsList(profile)
        }
        .padding(.vertical, 8)
    }

    private func xpBar(_ profile: UserProfile) -> some View {
        let xpToNext = LevelSystem.xpToNextLevel(currentXP: profile.xp)
        let xpThisLevel = profile.xp - LevelSystem.threshold(for: profile.level)
        let xpForLevel = LevelSystem.threshold(for: profile.level + 1) - LevelSystem.threshold(for: profile.level)
        let progress = xpForLevel > 0 ? Double(xpThisLevel) / Double(xpForLevel) : 0

        let total = 14
        let filled = Int(Double(total) * progress)
        let bar = String(repeating: "▓", count: filled) + String(repeating: "░", count: total - filled)

        return VStack(alignment: .leading, spacing: 2) {
            Text(bar)
                .font(.firaCode(10))
                .foregroundColor(.neonGreen)
            Text("\(xpToNext) XP TO NEXT LEVEL")
                .font(.firaCode(9))
                .foregroundColor(.white.opacity(0.4))
        }
    }

    private func achievementsList(_ profile: UserProfile) -> some View {
        let allKeys = ["streak_7", "streak_30", "level_10", "night_owl", "centurion", "perfect_week", "comeback_kid"]
        let unlockedKeys = Set(profile.achievements.map(\.key))

        return VStack(alignment: .leading, spacing: 6) {
            ForEach(allKeys, id: \.self) { key in
                let unlocked = unlockedKeys.contains(key)
                HStack(spacing: 6) {
                    Text(unlocked ? "◈" : "░")
                        .font(.firaCode(11))
                        .foregroundColor(unlocked ? .neonGreen : .white.opacity(0.2))
                    Text(key.uppercased().replacingOccurrences(of: "_", with: " "))
                        .font(.firaCode(10))
                        .foregroundColor(unlocked ? .white : .white.opacity(0.2))
                }
            }
        }
        .padding(.horizontal, 12)
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

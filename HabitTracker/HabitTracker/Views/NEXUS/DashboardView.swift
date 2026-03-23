import SwiftUI
import SwiftData

struct DashboardView: View {
    @EnvironmentObject private var coordinator: GamificationCoordinator
    @Query private var habits: [Habit]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                sectionHeader("ACTIVITY MATRIX // 365-DAY")
                heatmap
                    .padding(.horizontal, 12)
                    .padding(.bottom, 16)

                Divider().background(Color.neonGreen.opacity(0.15))

                sectionHeader("TODAY'S FEED")
                activityFeedView
            }
        }
        .background(Color.darkNavy)
    }

    private var heatmap: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days = (0..<365).map { offset -> Date in
            calendar.date(byAdding: .day, value: -(364 - offset), to: today)!
        }
        let allLogs = habits.flatMap(\.logs)
        let logsByDay = Dictionary(grouping: allLogs) { calendar.startOfDay(for: $0.date) }

        return LazyVGrid(columns: Array(repeating: GridItem(.fixed(10), spacing: 2), count: 52), spacing: 2) {
            ForEach(days, id: \.self) { day in
                let count = logsByDay[day]?.filter(\.completed).count ?? 0
                Rectangle()
                    .fill(heatmapColor(count: count))
                    .frame(width: 10, height: 10)
                    .help(formatDate(day))
            }
        }
    }

    private func heatmapColor(count: Int) -> Color {
        switch count {
        case 0:    return Color.dimGray
        case 1:    return Color.neonGreen.opacity(0.3)
        case 2:    return Color.neonGreen.opacity(0.6)
        default:   return Color.neonGreen
        }
    }

    private var activityFeedView: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(coordinator.activityLog.suffix(20).reversed(), id: \.self) { line in
                Text(line)
                    .font(.firaCode(10))
                    .foregroundColor(.neonGreen.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
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

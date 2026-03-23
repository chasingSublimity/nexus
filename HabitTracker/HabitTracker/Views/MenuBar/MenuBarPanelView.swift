import SwiftUI
import SwiftData

struct MenuBarPanelView: View {
    let onOpenNexus: () -> Void
    @EnvironmentObject private var coordinator: GamificationCoordinator
    @Query(filter: #Predicate<Habit> { !$0.isArchived },
           sort: \Habit.sortOrder) private var habits: [Habit]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("[NEURAL//HABITS]")
                    .font(.firaCode(11, weight: .bold))
                    .foregroundColor(.neonGreen)
                Spacer()
                Text("DAY ––")
                    .font(.firaCode(10))
                    .foregroundColor(.neonBlue)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.dimGray)

            Divider().background(Color.neonGreen.opacity(0.3))

            // Habit list
            ScrollView {
                VStack(spacing: 0) {
                    if habits.isEmpty {
                        Text("NO HABITS LOADED")
                            .font(.firaCode(11))
                            .foregroundColor(.white.opacity(0.3))
                            .padding()
                    } else {
                        ForEach(habits) { habit in
                            let todayLog = habit.logs.first { Calendar.current.isDateInToday($0.date) }
                            HabitRowView(
                                habit: habit,
                                log: todayLog,
                                onToggle: {
                                    coordinator.logAndProcess(
                                        habit: habit,
                                        date: Date(),
                                        completed: !(todayLog?.completed == true)
                                    )
                                },
                                onValueSet: { value in
                                    coordinator.logAndProcess(
                                        habit: habit,
                                        date: Date(),
                                        completed: true,
                                        value: value
                                    )
                                }
                            )
                            Divider().background(Color.white.opacity(0.05))
                        }
                    }
                }
            }
            .frame(maxHeight: 200)

            Divider().background(Color.neonGreen.opacity(0.3))

            // Footer
            HStack {
                Text("XP TODAY: +\(coordinator.todayXP)")
                    .font(.firaCode(10))
                    .foregroundColor(.neonBlue)
                Spacer()
                Button(action: onOpenNexus) {
                    Text("[OPEN NEXUS]")
                        .font(.firaCode(10, weight: .bold))
                        .foregroundColor(.neonGreen)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("open-nexus-button")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.dimGray)
        }
        .background(Color.voidBlack)
        .frame(width: 280)
    }
}

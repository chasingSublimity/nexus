import SwiftUI
import SwiftData

struct HabitsManagementView: View {
    @EnvironmentObject private var coordinator: GamificationCoordinator
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Habit> { !$0.isArchived },
           sort: \Habit.sortOrder) private var habits: [Habit]
    @State private var newHabitName = ""
    @State private var newHabitType: HabitType = .boolean
    @State private var newHabitDifficulty: Difficulty = .medium
    @State private var newHabitUnit = ""
    @State private var hoveringAdd = false
    @State private var hoveringType = false
    @State private var hoveringDifficulty = false
    @State private var hoveringArchiveID: UUID? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                TextField("NEW HABIT NAME", text: $newHabitName)
                    .font(.firaCode(11))
                    .foregroundColor(.neonGreen)
                    .textFieldStyle(.plain)
                    .onSubmit { addHabit() }

                // Two options — click to toggle
                Button(action: { newHabitType = newHabitType == .boolean ? .quantified : .boolean }) {
                    Text("[\(newHabitType == .boolean ? "TASK" : "GOAL")]")
                        .font(.firaCode(11))
                        .foregroundColor(.neonGreen.opacity(hoveringType ? 0.5 : 1.0))
                }
                .buttonStyle(.plain)
                .onHover { hoveringType = $0 }

                // Three options — click to cycle
                Button(action: cycleDifficulty) {
                    Text("[\(newHabitDifficulty.label)]")
                        .font(.firaCode(11))
                        .foregroundColor(.neonGreen.opacity(hoveringDifficulty ? 0.5 : 1.0))
                }
                .buttonStyle(.plain)
                .onHover { hoveringDifficulty = $0 }

                let nameIsEmpty = newHabitName.trimmingCharacters(in: .whitespaces).isEmpty
                Button(action: addHabit) {
                    Text("[+ ADD]")
                        .font(.firaCode(11, weight: .bold))
                        .foregroundColor(
                            nameIsEmpty       ? .neonGreen.opacity(0.2) :
                            hoveringAdd       ? .neonGreen               :
                                               .neonGreen.opacity(0.55)
                        )
                }
                .buttonStyle(.plain)
                .disabled(nameIsEmpty)
                .onHover { hoveringAdd = $0 }
            }
            .padding(12)
            .background(Color.voidBlack)

            Divider().background(Color.neonGreen.opacity(0.2))

            List {
                ForEach(habits) { habit in
                    HStack(spacing: 8) {
                        Image(systemName: habit.icon)
                            .foregroundColor(Color(hex: habit.color))
                        Text(habit.name.uppercased())
                            .font(.firaCode(12))
                            .foregroundColor(.white)
                        Text(habit.difficulty.label)
                            .font(.firaCode(9))
                            .foregroundColor(.neonBlue.opacity(0.6))
                        Spacer()
                        Button(action: { archiveHabit(habit) }) {
                            Text("[ARCHIVE]")
                                .font(.firaCode(9))
                                .foregroundColor(
                                    hoveringArchiveID == habit.id
                                        ? .neonPink
                                        : .neonPink.opacity(0.3)
                                )
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in hoveringArchiveID = hovering ? habit.id : nil }
                    }
                    .listRowBackground(Color.darkNavy)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.darkNavy)
        }
    }

    private func cycleDifficulty() {
        newHabitDifficulty = newHabitDifficulty.next()
    }

    private func addHabit() {
        let name = newHabitName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let habit = Habit(
            name: name,
            type: newHabitType,
            difficulty: newHabitDifficulty,
            sortOrder: habits.count
        )
        if newHabitType == .quantified && !newHabitUnit.isEmpty {
            habit.unit = newHabitUnit
        }
        modelContext.insert(habit)
        try? modelContext.save()
        newHabitName = ""
        newHabitUnit = ""
        coordinator.rebuildNotifications()
    }

    private func archiveHabit(_ habit: Habit) {
        habit.isArchived = true
        try? modelContext.save()
        coordinator.rebuildNotifications()
    }
}

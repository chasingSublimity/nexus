import SwiftUI
import SwiftData

struct HabitsManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Habit> { !$0.isArchived },
           sort: \Habit.sortOrder) private var habits: [Habit]
    @State private var newHabitName = ""
    @State private var newHabitType: HabitType = .boolean
    @State private var newHabitDifficulty: Difficulty = .medium
    @State private var newHabitUnit = ""

    var body: some View {
        VStack(spacing: 0) {
            // Add habit bar
            HStack {
                TextField("NEW HABIT NAME", text: $newHabitName)
                    .font(.firaCode(11))
                    .foregroundColor(.neonGreen)
                    .textFieldStyle(.plain)

                Picker("", selection: $newHabitType) {
                    Text("BOOL").tag(HabitType.boolean)
                    Text("QTY").tag(HabitType.quantified)
                }
                .labelsHidden()
                .frame(width: 70)

                Picker("", selection: $newHabitDifficulty) {
                    ForEach(Difficulty.allCases, id: \.self) { d in
                        Text(d.label).tag(d)
                    }
                }
                .labelsHidden()
                .frame(width: 70)

                Button(action: addHabit) {
                    Text("[+ ADD]")
                        .font(.firaCode(11, weight: .bold))
                        .foregroundColor(.neonGreen)
                }
                .buttonStyle(.plain)
                .disabled(newHabitName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(12)
            .background(Color.voidBlack)

            Divider().background(Color.neonGreen.opacity(0.2))

            List {
                ForEach(habits) { habit in
                    HStack {
                        Image(systemName: habit.icon)
                            .foregroundColor(Color(hex: habit.color))
                        Text(habit.name.uppercased())
                            .font(.firaCode(12))
                            .foregroundColor(.white)
                        Spacer()
                        Text(habit.difficulty.label)
                            .font(.firaCode(9))
                            .foregroundColor(.neonBlue.opacity(0.6))
                        Button(action: { archiveHabit(habit) }) {
                            Text("[ARCHIVE]")
                                .font(.firaCode(9))
                                .foregroundColor(.neonPink.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                    }
                    .listRowBackground(Color.darkNavy)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.darkNavy)
        }
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
    }

    private func archiveHabit(_ habit: Habit) {
        habit.isArchived = true
        try? modelContext.save()
    }
}

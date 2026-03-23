import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let log: HabitLog?     // today's log, nil if not yet completed
    let onToggle: () -> Void
    let onValueSet: (Double) -> Void

    @State private var quantifiedInput: String = ""

    var body: some View {
        HStack(spacing: 8) {
            // Status indicator
            Circle()
                .fill(log?.completed == true ? Color(hex: habit.color) : Color.dimGray)
                .frame(width: 8, height: 8)
                .shadow(color: Color(hex: habit.color).opacity(log?.completed == true ? 0.8 : 0), radius: 6)

            Text("◈ \(habit.name.uppercased())")
                .font(.firaCode(12, weight: .medium))
                .foregroundColor(log?.completed == true ? Color(hex: habit.color) : .white.opacity(0.7))

            Spacer()

            if habit.type == .quantified {
                if log?.completed == true {
                    Text("\(log?.value ?? 0, specifier: "%.1f") \(habit.unit ?? "")")
                        .font(.firaCode(11))
                        .foregroundColor(Color(hex: habit.color))
                } else {
                    TextField("0.0", text: $quantifiedInput)
                        .font(.firaCode(11))
                        .foregroundColor(.neonBlue)
                        .frame(width: 50)
                        .multilineTextAlignment(.trailing)
                        .onSubmit {
                            if let val = Double(quantifiedInput) {
                                onValueSet(val)
                            }
                        }
                    Text(habit.unit ?? "").font(.firaCode(11)).foregroundColor(.white.opacity(0.4))
                }
            } else {
                Button(action: onToggle) {
                    Text(log?.completed == true ? "[✓ DONE]" : "[LOG]")
                        .font(.firaCode(11, weight: .bold))
                        .foregroundColor(log?.completed == true ? Color(hex: habit.color) : .neonGreen)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .onChange(of: habit.id) { quantifiedInput = "" }
    }
}

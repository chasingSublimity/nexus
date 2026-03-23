import SwiftUI

struct MenuBarPanelView: View {
    let onOpenNexus: () -> Void

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

            // Habit list placeholder — replaced by real data in Task 16
            VStack(spacing: 0) {
                Text("NO HABITS LOADED")
                    .font(.firaCode(11))
                    .foregroundColor(.white.opacity(0.3))
                    .padding()
            }

            Divider().background(Color.neonGreen.opacity(0.3))

            // Footer
            HStack {
                Text("XP TODAY: +0")
                    .font(.firaCode(10))
                    .foregroundColor(.neonBlue)
                Spacer()
                Button(action: onOpenNexus) {
                    Text("[OPEN NEXUS]")
                        .font(.firaCode(10, weight: .bold))
                        .foregroundColor(.neonGreen)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.dimGray)
        }
        .background(Color.voidBlack)
        .frame(width: 280)
    }
}

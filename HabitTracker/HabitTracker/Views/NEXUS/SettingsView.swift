import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var profiles: [UserProfile]
    private var profile: UserProfile? { profiles.first }
    @Environment(\.modelContext) private var modelContext
    @State private var hoveringMotion = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("SETTINGS")

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("REDUCE MOTION")
                        .font(.firaCode(11))
                        .foregroundColor(.white.opacity(0.8))
                    Text("DISABLES SCAN LINES AND ANIMATIONS")
                        .font(.firaCode(8))
                        .foregroundColor(.white.opacity(0.3))
                }
                Spacer()
                Button(action: toggleReduceMotion) {
                    let on = profile?.reduceMotion ?? false
                    Text("[\(on ? "ON" : "OFF")]")
                        .font(.firaCode(11, weight: .bold))
                        .foregroundColor(
                            on
                                ? .neonGreen.opacity(hoveringMotion ? 0.5 : 1.0)
                                : .white.opacity(hoveringMotion ? 0.4 : 0.2)
                        )
                }
                .buttonStyle(.plain)
                .onHover { hoveringMotion = $0 }
            }
            .padding(12)
            .background(Color.darkNavy)

            Spacer()
        }
        .background(Color.darkNavy)
    }

    private func toggleReduceMotion() {
        guard let profile else { return }
        profile.reduceMotion.toggle()
        try? modelContext.save()
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

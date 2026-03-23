import AppKit
import SwiftUI

struct NexusView: View {
    let renderer: AnyEffectRenderer
    let onClose: () -> Void
    @State private var activeTab: NexusTab = .dashboard
    @State private var isGlitching = false
    @State private var glitchOffset: CGFloat = 0
    @State private var hoveringQuit = false

    var body: some View {
        ZStack {
            Color.voidBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                // Title bar
                titleBar

                Divider().background(Color.neonGreen.opacity(0.4))

                // Three-column layout
                HStack(spacing: 0) {
                    // Left: Habit Roster (fixed width)
                    HabitRosterView()
                        .frame(width: 200)

                    Divider().background(Color.neonGreen.opacity(0.2))

                    // Center: tab-switched content
                    centerPanel
                        .frame(maxWidth: .infinity)

                    Divider().background(Color.neonGreen.opacity(0.2))

                    // Right: Agent Stats (fixed width)
                    AgentStatsView()
                        .frame(width: 180)
                }
            }

            // Scan line overlay
            if renderer.isMotionEnabled {
                GeometryReader { geo in
                    TimelineView(.animation) { timeline in
                        let phase = timeline.date.timeIntervalSince1970.truncatingRemainder(dividingBy: 4) / 4
                        renderer.overlay(in: geo.frame(in: .local), phase: phase)
                    }
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
        }
        .overlay(alignment: .leading)  { CursorZone(cursor: .resizeLeftRight).frame(width: 6) }
        .overlay(alignment: .trailing) { CursorZone(cursor: .resizeLeftRight).frame(width: 6) }
        .overlay(alignment: .bottom)   { CursorZone(cursor: .resizeUpDown).frame(height: 6) }
        .offset(x: isGlitching ? glitchOffset : 0)
        .onChange(of: isGlitching) { _, glitching in
            if glitching { glitchOffset = CGFloat.random(in: -3...3) }
        }
    }

    private var titleBar: some View {
        HStack(spacing: 0) {
            Text("◈ HABIT//OS")
                .font(.firaCode(13, weight: .bold))
                .foregroundColor(.neonGreen)
                .padding(.leading, 16)

            Spacer()

            // Nav tabs
            HStack(spacing: 0) {
                ForEach(NexusTab.allCases, id: \.self) { tab in
                    Button(action: { activeTab = tab }) {
                        Text("[\(tab.rawValue)]")
                            .font(.firaCode(11, weight: activeTab == tab ? .bold : .regular))
                            .foregroundColor(activeTab == tab ? .neonGreen : .white.opacity(0.4))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            Button(action: onClose) {
                Text("✕")
                    .font(.firaCode(12))
                    .foregroundColor(hoveringQuit ? .neonPink : .neonPink.opacity(0.35))
                    .scaleEffect(hoveringQuit ? 1.15 : 1.0)
                    .animation(.easeOut(duration: 0.1), value: hoveringQuit)
            }
            .buttonStyle(.plain)
            .onHover { hoveringQuit = $0 }
            .padding(.trailing, 16)
            .accessibilityIdentifier("nexus-close-button")
        }
        .frame(height: 40)
        .background(Color.darkNavy)
    }

    @ViewBuilder
    private var centerPanel: some View {
        switch activeTab {
        case .dashboard:    DashboardView()
        case .habits:       HabitsManagementView()
        case .achievements: AchievementsView()
        case .settings:     SettingsView()
        }
    }
}

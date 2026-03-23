import AppKit
import SwiftUI

struct NexusView: View {
    let renderer: AnyEffectRenderer
    @State private var activeTab: NexusTab = .dashboard
    @State private var isGlitching = false

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
        .offset(x: isGlitching ? CGFloat.random(in: -3...3) : 0)
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

            Button(action: { Task { @MainActor in NSApp.terminate(nil) } }) {
                Text("✕")
                    .font(.firaCode(12))
                    .foregroundColor(.neonPink.opacity(0.6))
            }
            .buttonStyle(.plain)
            .padding(.trailing, 16)
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

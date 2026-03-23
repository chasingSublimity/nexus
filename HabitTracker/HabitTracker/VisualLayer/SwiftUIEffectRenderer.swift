import SwiftUI
import AppKit

@MainActor
final class SwiftUIEffectRenderer: EffectRenderer {

    private let userReduceMotion: @Sendable () -> Bool

    init(userReduceMotion: @escaping @Sendable () -> Bool = { false }) {
        self.userReduceMotion = userReduceMotion
    }

    var isMotionEnabled: Bool {
        !userReduceMotion() && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    // MARK: - Overlay (scan lines)

    @ViewBuilder
    func overlay(in rect: CGRect, phase: Double) -> some View {
        if isMotionEnabled {
            Canvas { context, size in
                let lineSpacing: CGFloat = 4
                var y: CGFloat = 0
                while y < size.height {
                    let alpha = 0.03 + 0.02 * sin(y / 20 + phase * .pi * 2)
                    context.fill(
                        Path(CGRect(x: 0, y: y, width: size.width, height: 1)),
                        with: .color(.black.opacity(alpha))
                    )
                    y += lineSpacing
                }
            }
            .allowsHitTesting(false)
        }
    }

    // MARK: - Glow Modifier

    struct NeonGlowModifier: ViewModifier {
        let color: Color
        let intensity: Double
        let motionEnabled: Bool

        func body(content: Content) -> some View {
            if motionEnabled {
                content
                    .shadow(color: color.opacity(0.8 * intensity), radius: 4)
                    .shadow(color: color.opacity(0.5 * intensity), radius: 8)
                    .shadow(color: color.opacity(0.3 * intensity), radius: 16)
            } else {
                content
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(color.opacity(0.6), lineWidth: 1)
                    )
            }
        }
    }

    func glowModifier(color: Color, intensity: Double) -> NeonGlowModifier {
        NeonGlowModifier(color: color, intensity: intensity, motionEnabled: isMotionEnabled)
    }

    // MARK: - Glitch

    func triggerGlitch(duration: Double, isGlitching: Binding<Bool>) {
        guard isMotionEnabled, !isGlitching.wrappedValue else { return }
        withAnimation(.easeIn(duration: 0.05)) {
            isGlitching.wrappedValue = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration))
            withAnimation(.easeOut(duration: 0.1)) {
                isGlitching.wrappedValue = false
            }
        }
    }
}

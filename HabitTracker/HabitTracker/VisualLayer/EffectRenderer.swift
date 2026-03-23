import SwiftUI
import AppKit
import Combine

// MARK: - Protocol

protocol EffectRenderer {
    associatedtype GlowModifier: ViewModifier
    associatedtype OverlayView: View

    /// False when in-app reduceMotion is enabled OR system Reduce Motion is on.
    var isMotionEnabled: Bool { get }

    /// Full-screen overlay (scan lines, noise). Returns EmptyView when motion disabled.
    @ViewBuilder func overlay(in rect: CGRect, phase: Double) -> OverlayView

    /// Neon glow modifier. Returns a static border modifier when motion disabled.
    func glowModifier(color: Color, intensity: Double) -> GlowModifier

    /// Triggers a glitch animation by toggling `isGlitching`. No-ops when motion disabled.
    func triggerGlitch(duration: Double, isGlitching: Binding<Bool>)
}

// MARK: - Type Eraser

/// Wraps any EffectRenderer for use as a concrete type in environment/injection.
final class AnyEffectRenderer: ObservableObject {
    let objectWillChange = PassthroughSubject<Void, Never>()

    private let _isMotionEnabled: () -> Bool
    private let _overlay: (CGRect, Double) -> AnyView
    private let _glowModifier: (Color, Double) -> AnyViewModifier
    private let _triggerGlitch: (Double, Binding<Bool>) -> Void

    init<R: EffectRenderer>(_ renderer: R) {
        _isMotionEnabled = { renderer.isMotionEnabled }
        _overlay = { rect, phase in AnyView(renderer.overlay(in: rect, phase: phase)) }
        _glowModifier = { color, intensity in AnyViewModifier(renderer.glowModifier(color: color, intensity: intensity)) }
        _triggerGlitch = { duration, binding in renderer.triggerGlitch(duration: duration, isGlitching: binding) }
    }

    var isMotionEnabled: Bool { _isMotionEnabled() }

    func overlay(in rect: CGRect, phase: Double) -> AnyView {
        _overlay(rect, phase)
    }

    func glowModifier(color: Color, intensity: Double) -> AnyViewModifier {
        _glowModifier(color, intensity)
    }

    func triggerGlitch(duration: Double, isGlitching: Binding<Bool>) {
        _triggerGlitch(duration, isGlitching)
    }
}

// MARK: - AnyViewModifier helper

struct AnyViewModifier: ViewModifier {
    private let _body: (Content) -> AnyView
    init<M: ViewModifier>(_ modifier: M) {
        _body = { AnyView($0.modifier(modifier)) }
    }
    func body(content: Content) -> some View {
        _body(content)
    }
}

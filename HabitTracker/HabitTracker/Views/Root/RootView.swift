import SwiftUI

struct RootView: View {
    let renderer: AnyEffectRenderer
    let onClose: () -> Void

    var body: some View {
        NexusView(renderer: renderer, onClose: onClose)
            .environmentObject(renderer)
    }
}

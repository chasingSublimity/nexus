import SwiftUI

struct RootView: View {
    let renderer: AnyEffectRenderer

    var body: some View {
        NexusView(renderer: renderer)
            .environmentObject(renderer)
    }
}

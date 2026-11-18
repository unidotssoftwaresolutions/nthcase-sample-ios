import MossgroveKit
import SwiftUI
import UIKit

/// Lobby (UIKit): SwiftUI draws the top bar, as for Settings; everything under it is `LobbyViewController`.
struct LobbyUIKitScreen: View {
    @Environment(AppModel.self) private var model
    @State private var holder = ControllerHolder()

    final class ControllerHolder {
        weak var controller: LobbyViewController?
    }

    var body: some View {
        LobbyHost(model: model, holder: holder)
            .ignoresSafeArea(.container, edges: .bottom)
            .screenBackground()
            .topBar(Lobby.titleUIKit, back: true, onBack: { holder.controller?.backClosesPanel() ?? false })
    }
}

private struct LobbyHost: UIViewControllerRepresentable {
    let model: AppModel
    let holder: LobbyUIKitScreen.ControllerHolder

    func makeUIViewController(context: Context) -> LobbyViewController {
        let controller = LobbyViewController(model: model)
        holder.controller = controller
        return controller
    }

    func updateUIViewController(_ controller: LobbyViewController, context: Context) {}
}

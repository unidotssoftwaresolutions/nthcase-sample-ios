import MossgroveKit
import SwiftUI

/// SwiftUI draws the top bar; the body is the UIKit screen, so this one screen exercises UIKit.
struct SettingsScreen: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        SettingsHost(model: model)
            .ignoresSafeArea(.container, edges: .bottom)
            .screenBackground()
            .topBar(AppTab.settings.title)
    }
}

private struct SettingsHost: UIViewControllerRepresentable {
    let model: AppModel

    func makeUIViewController(context: Context) -> SettingsViewController { SettingsViewController(model: model) }

    func updateUIViewController(_ controller: SettingsViewController, context: Context) { controller.render() }
}

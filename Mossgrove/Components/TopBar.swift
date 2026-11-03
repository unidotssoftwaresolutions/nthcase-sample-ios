import MossgroveKit
import SwiftUI
import UIKit

extension View {
    /// The top bar: the screen's title, and Back on screens below a tab. `tagged: false` leaves out the ids, for the
    /// gift-cards screen.
    func topBar(_ title: String, back: Bool = false, tagged: Bool = true) -> some View {
        modifier(TopBar(title: title, back: back, tagged: tagged))
    }

    /// An accessibility identifier, or none.
    @ViewBuilder
    func testId(_ id: String?) -> some View {
        if let id { accessibilityIdentifier(id) } else { self }
    }
}

/// The title is a toolbar item of its own, so it can carry `top_bar_title`; the system's title would not. Back is
/// the app's own button, so it can carry `top_bar_back`; the edge swipe still works (PopGesture).
private struct TopBar: ViewModifier {
    let title: String
    let back: Bool
    let tagged: Bool
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(back)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                        .accessibilityAddTraits(.isHeader)
                        .testId(tagged ? TestIds.topBarTitle : nil)
                }
                if back {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { dismiss() } label: { Image(systemName: "chevron.backward").fontWeight(.semibold) }
                            .accessibilityLabel("Back")
                            .testId(tagged ? TestIds.topBarBack : nil)
                    }
                }
            }
            .background { if back { PopGesture() } }
    }
}

/// Hiding the system's Back also turns off the edge swipe that goes back. This turns it on again: the swipe pops
/// whenever there is a screen to go back to (SPEC.md §4).
private struct PopGesture: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Enabler { Enabler() }
    func updateUIViewController(_ controller: Enabler, context: Context) {}

    final class Enabler: UIViewController {
        override func loadView() {
            view = UIView()
            view.isUserInteractionEnabled = false
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            guard let navigation = navigationController ?? parent?.navigationController else { return }
            let delegate = PopDelegate(navigation)
            objc_setAssociatedObject(navigation, &PopDelegate.key, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            navigation.interactivePopGestureRecognizer?.delegate = delegate
            navigation.interactivePopGestureRecognizer?.isEnabled = true
            if #available(iOS 26.0, *) {
                navigation.interactiveContentPopGestureRecognizer?.delegate = delegate
            }
        }
    }

    final class PopDelegate: NSObject, UIGestureRecognizerDelegate {
        nonisolated(unsafe) static var key: UInt8 = 0
        private weak var navigation: UINavigationController?

        init(_ navigation: UINavigationController) { self.navigation = navigation }

        func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
            (navigation?.viewControllers.count ?? 0) > 1
        }
    }
}

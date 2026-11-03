import MossgroveKit
import SwiftUI
import WebKit

/// The care guide: the bundled page `care-guide.html` in a WKWebView, with a status line above it. The page loads
/// nothing remote: its own policy forbids it, a content rule blocks every http(s) load, and links leaving the page are
/// refused.
struct CareGuideView: View {
    @State private var status = Texts.pageLoading

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(status)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color(Palette.onSurfaceVariant))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .accessibilityIdentifier(TestIds.webviewStatus)
            CareGuidePage { status = Texts.pageLoaded }
        }
        .screenBackground()
        .container(TestIds.webviewScreen)
        .topBar("Care guide", back: true)
    }
}

private struct CareGuidePage: UIViewRepresentable {
    let onLoaded: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onLoaded: onLoaded) }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        let web = WKWebView(frame: .zero, configuration: configuration)
        web.navigationDelegate = context.coordinator
        web.isOpaque = false
        web.backgroundColor = Palette.surface
        web.accessibilityIdentifier = TestIds.webview
        #if DEBUG
        // Debug builds let Appium switch into the page's WEBVIEW context; release builds do not (SPEC.md §5).
        web.isInspectable = true
        #endif
        context.coordinator.load(into: web)
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let onLoaded: () -> Void
        private let page = Bundle.main.url(forResource: "care-guide", withExtension: "html")!

        init(onLoaded: @escaping () -> Void) { self.onLoaded = onLoaded }

        /// Blocks every http(s) request first, then loads the page from the app's own bundle.
        func load(into web: WKWebView) {
            let rules = #"[{"trigger":{"url-filter":"^https?:"},"action":{"type":"block"}}]"#
            WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "mossgrove-no-network", encodedContentRuleList: rules) { [page] list, _ in
                if let list { web.configuration.userContentController.add(list) }
                web.loadFileURL(page, allowingReadAccessTo: page.deletingLastPathComponent())
            }
        }

        /// The page and its own anchors only.
        func webView(_ web: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void) {
            let url = action.request.url
            let samePage = url?.isFileURL == true && url?.path == page.path
            decisionHandler(samePage || url?.absoluteString == "about:blank" ? .allow : .cancel)
        }

        func webView(_ web: WKWebView, didFinish navigation: WKNavigation!) { onLoaded() }
    }
}

import MossgroveKit
import SwiftUI

/// The Lab: Mossgrove's second cabinet, one row per test bench. It says plainly what each one is for.
struct LabView: View {
    @Environment(AppModel.self) private var model

    private struct Bench: Identifiable {
        let id: String
        let route: Route
        let title: String
        let body: String
    }

    private let benches = [
        Bench(id: TestIds.labForm, route: .form, title: "Join the club", body: "A form: text, email, number, password, picker, date, switch, slider, checkbox"),
        Bench(id: TestIds.labGestures, route: .gestures, title: "Gestures", body: "Tap, double tap, long press, swipe, drag and drop, pinch, rotate, scroll, shake"),
        Bench(id: TestIds.labWebview, route: .careGuide, title: "Care guide", body: "A web page inside the app, bundled with it"),
        Bench(id: TestIds.labSlow, route: .slow, title: "Delivery slots", body: "Loads for 3 seconds, then shows its content"),
        Bench(id: TestIds.labOrders, route: .orders, title: "Orders", body: "An empty state, and an error state with retry"),
        Bench(id: TestIds.labGiftCards, route: .giftCards, title: "Gift cards", body: "No test ids at all: find things by their text"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(Texts.labIntro)
                    .font(.subheadline)
                    .foregroundStyle(Color(Palette.onSurfaceVariant))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                ForEach(benches) { bench in
                    Button { model.navigation.push(bench.route) } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(bench.title).font(.body).foregroundStyle(Color(Palette.onSurface))
                                Text(bench.body).font(.subheadline).foregroundStyle(Color(Palette.onSurfaceVariant))
                            }
                            Spacer()
                            Art.icon("chevron").foregroundStyle(Color(Palette.onSurfaceVariant))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(minHeight: 56)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(bench.id)
                    Divider().overlay(Color(Palette.outlineVariant)).padding(.horizontal, 16)
                }
            }
        }
        .screenBackground()
        .container(TestIds.labScreen)
        .topBar(AppTab.lab.title)
    }
}

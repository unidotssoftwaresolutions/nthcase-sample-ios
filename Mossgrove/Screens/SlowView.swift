import MossgroveKit
import SwiftUI

/// Always slow: "Finding delivery slots…" for 3 s, then the five slots. Reload waits again.
struct SlowView: View {
    @Environment(AppModel.self) private var model
    @State private var load = LoadModel()

    var body: some View {
        ZStack {
            switch load.status {
            case .loading:
                LoadingView(text: Texts.slotsLoading, id: TestIds.slowLoading)
            case .failed:
                StateMessage(icon: "warning", title: "Slots didn't load", message: "Something went wrong on our side.",
                             id: nil, actionLabel: Texts.tryAgain, isError: true) {
                    load.retry(slow: true, fail: model.failFirstLoad)
                }
            case .ready:
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Texts.slotsIntro)
                            .font(.subheadline)
                            .foregroundStyle(Color(Palette.onSurfaceVariant))
                            .padding(16)
                        ForEach(Array(Texts.slots.enumerated()), id: \.offset) { index, slot in
                            Text(slot)
                                .font(.body)
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                                .accessibilityIdentifier(TestIds.slowSlot(index + 1))
                        }
                        Button(Texts.reload) { load.start(slow: true, fail: model.failFirstLoad) }
                            .buttonStyle(OutlinedButtonStyle(fullWidth: true))
                            .padding(16)
                            .accessibilityIdentifier(TestIds.slowReload)
                    }
                    .foregroundStyle(Color(Palette.onSurface))
                }
                .scrollingList(TestIds.slowContent)
            }
        }
        .screenBackground()
        .container(TestIds.slowScreen)
        .topBar("Delivery slots", back: true)
        .onAppear { load.start(slow: true, fail: model.failFirstLoad) }
        .onDisappear { load.stop() }
    }
}

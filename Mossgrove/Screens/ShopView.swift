import MossgroveKit
import SwiftUI

/// The long list: 40 drawers behind a search, pull to refresh, and the empty, loading and error states.
struct ShopView: View {
    @Environment(AppModel.self) private var model
    @State private var query = ""
    @State private var load = LoadModel()
    @FocusState private var searchFocused: Bool

    var body: some View {
        let results = Catalog.search(query)
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text(Texts.appName).font(.largeTitle.weight(.bold)).accessibilityAddTraits(.isHeader)
                // The magnifier and the space around the text are part of the field: a tap anywhere in the box
                // puts the cursor in it. "Search" is the field's title, so it is the field's own label.
                FieldBox(trailing: 0, focus: { searchFocused = true }) {
                    HStack(spacing: 8) {
                        Art.icon("search").foregroundStyle(Color(Palette.onSurfaceVariant)).accessibilityHidden(true)
                        TextField("Search", text: $query, prompt: Text(Texts.searchPlaceholder))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.search)
                            .focused($searchFocused)
                            .accessibilityIdentifier(TestIds.shopSearch)
                        if !query.isEmpty {
                            Button { query = "" } label: { Art.icon("close").frame(width: 44, height: 44) }
                                .foregroundStyle(Color(Palette.onSurfaceVariant))
                                .accessibilityLabel(Texts.clearSearch)
                                .accessibilityIdentifier(TestIds.shopSearchClear)
                        }
                    }
                }
                if load.status == .ready {
                    Text(Catalog.countLine(query: query, results: results.count))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color(Palette.onSurfaceVariant))
                        .accessibilityIdentifier(TestIds.shopCount)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 8)

            switch load.status {
            case .loading:
                LoadingView(text: Texts.shopLoading, id: TestIds.shopLoading)
            case .failed:
                StateMessage(icon: "warning", title: Texts.shopFailed, message: Texts.shopFailedHelp, id: TestIds.shopError,
                             actionLabel: Texts.tryAgain, actionId: TestIds.shopRetry, isError: true) {
                    load.retry(slow: model.slowLoading, fail: model.failFirstLoad)
                }
            case .ready:
                ScrollView {
                    if results.isEmpty {
                        StateMessage(icon: "empty", title: Texts.noMatch(query.trimmingCharacters(in: .whitespaces)),
                                     message: Texts.noMatchHelp, id: TestIds.shopEmpty,
                                     actionLabel: Texts.clearSearch, actionId: TestIds.shopEmptyAction) { query = "" }
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(results) { item in
                                DrawerRow(item: item) { model.navigation.push(.item(String(item.id))) }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
                // as on every screen: a drag on the list lowers the keyboard, nothing else does
                .scrollDismissesKeyboard(.interactively)
                .refreshable { await refresh() }
                .scrollingList(TestIds.shopList)
            }
        }
        .screenBackground()
        .container(TestIds.shopScreen)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { load.start(slow: model.slowLoading, fail: model.failFirstLoad) }
        .onDisappear { load.stop() }
    }

    /// Pull to refresh: 0.8 s (3 s when Slow loading is on), then the snackbar.
    private func refresh() async {
        try? await Task.sleep(for: .seconds(model.slowLoading ? LoadPlan.slowSeconds : LoadPlan.refreshSeconds))
        model.showSnack(Texts.refreshed)
    }
}

/// One drawer front: the drawing on its aisle's tint, the label holder, the price. The whole row is one button that
/// reads the name, the number and the price, and carries the item's id.
private struct DrawerRow: View {
    let item: Item
    let open: () -> Void

    var body: some View {
        Button(action: open) {
            HStack(spacing: 12) {
                GlyphTile(item: item, size: 56)
                LabelHolder(item: item)
                Spacer(minLength: 12)
                Text(item.price).font(.headline).foregroundStyle(Color(Palette.onSurface))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(Palette.surfaceContainerLow), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens \(item.name)")
        .accessibilityIdentifier(TestIds.shopItem(item.id))
    }
}

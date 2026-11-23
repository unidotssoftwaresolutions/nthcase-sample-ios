import MossgroveKit
import SwiftUI

/// The Lobby, built with SwiftUI (SPEC.md §5 and §12, new in 1.1): a test bench for scrolling.
///
/// Top to bottom, and in that order in the tree: the touch log, "Saved appears after" with Show the pager, the promo
/// pager (left out of the view while Show the pager is off), the Top 10 row, the page, and the Lobby's own bar. The
/// pager and the Top 10 row sit above the page, outside it, so that one of them is the first scroll view in the tree.
/// Every scroller is SwiftUI's own `ScrollView`. Every touchable element takes SwiftUI's own double tap, tap and long
/// press, and the log is the only thing the Lobby adds.
struct LobbyView: View {
    @Environment(AppModel.self) private var model
    @State private var log = TouchLog()
    @State private var panel: LobbyPanel?
    @State private var sheet: LobbySheetTarget?
    @State private var barSelected = "Home"
    @State private var chip = 1
    @State private var auto = false
    @State private var banner: Int? = 1
    /// When the count toward Saved started: the Lobby's opening, then each choice of a delay.
    @State private var clockStart = Date.now
    @State private var savedArrived = false

    /// Saved is in the bar once its delay has passed: until then it is not in the view at all.
    private var savedShown: Bool { savedArrived || model.lobbySavedDelay == 0 }

    var body: some View {
        VStack(spacing: 0) {
            TouchLogBlock(log: $log)
            DelayChoice(delay: model.lobbySavedDelay, pagerShown: model.lobbyPagerShown, choose: choose, showPager: { model.lobbyPagerShown = $0 })
            ZStack(alignment: .top) {
                // The Lobby stays under a panel, hidden from sight, touch and accessibility, so every scroller is where
                // it was when the panel closes.
                lobby
                    .opacity(panel == nil ? 1 : 0)
                    .allowsHitTesting(panel == nil)
                    .accessibilityHidden(panel != nil)
                if let panel {
                    panelView(panel)
                }
            }
            .frame(maxHeight: .infinity)
            bar
        }
        .screen(TestIds.lobbyScreen)
        .screenBackground()
        .topBar(Lobby.title, back: true, onBack: closePanel)
        .sheet(item: $sheet) { target in
            QuickSheet(target: target) { label in
                log.add(.tap, label, "quick sheet, \(target.title)")
                sheet = nil
                if label == "Open" { panel = target.opens }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .task(id: clockStart) {
            let clock = SavedClock(delay: model.lobbySavedDelay, started: clockStart)
            savedArrived = clock.shown(at: .now)
            let wait = clock.remaining(at: .now)
            if wait > 0 {
                try? await Task.sleep(for: .seconds(wait))
                if Task.isCancelled { return }
            }
            savedArrived = true
        }
    }

    // MARK: Parts

    private var lobby: some View {
        VStack(spacing: 0) {
            // off, the pager and its position line are left out of the view: no node in the tree, not hidden
            if model.lobbyPagerShown {
                PagerBlock(banner: $banner, auto: $auto, log: $log, onPromo: { panel = .promo($0) }, onSheet: { sheet = $0 })
            }
            TopRow(log: $log, onDetail: { panel = .detail(row: Lobby.topRow, tile: $0) }, onSheet: { sheet = $0 })
            LobbyPage(log: $log, chip: $chip, onDetail: { panel = .detail(row: $0, tile: $1) }, onSheet: { sheet = $0 })
        }
    }

    /// The Lobby's own bar, not the app's tab bar: four buttons, Saved left out until its delay has passed.
    private var bar: some View {
        HStack(spacing: 0) {
            barItem("Home", id: TestIds.lobbyBarHome)
            barItem("Live", id: TestIds.lobbyBarLive)
            if savedShown {
                barItem("Saved", id: TestIds.lobbyBarSaved)
            }
            barItem("Offers", id: TestIds.lobbyBarOffers)
        }
        .frame(minHeight: 52)
        .background {
            Color(Palette.surfaceContainer)
                .overlay(alignment: .top) { Color(Palette.outlineVariant).frame(height: 0.5) }
                .ignoresSafeArea(edges: .bottom)
        }
        .container(TestIds.lobbyBar)
    }

    private func barItem(_ label: String, id: String) -> some View {
        let selected = barSelected == label
        return Button {
            log.add(.tap, label, "bar")
            barSelected = label
            panel = label == "Saved" ? .saved : nil
        } label: {
            VStack(spacing: 2) {
                Art.icon(LobbyArt.barIcon(label)).resizable().frame(width: 22, height: 22)
                Text(label).font(.caption2.weight(.medium))
            }
            .foregroundStyle(selected ? Color(Palette.primary) : Color(Palette.onSurfaceVariant))
            .frame(maxWidth: .infinity, minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier(id)
    }

    @ViewBuilder
    private func panelView(_ panel: LobbyPanel) -> some View {
        switch panel {
        case .detail(let row, let tile):
            let item = Lobby.item(row: row, tile: tile)
            PanelColumn {
                GlyphTile(item: item, size: 96).accessibilityElement().accessibilityLabel(Texts.drawingOf(item.name))
                Text(item.name).font(.title2.weight(.semibold)).multilineTextAlignment(.center)
                ItemNumber(item: item)
                Text(Lobby.detailPlace(row: row, tile: tile)).font(.body)
                Button(Lobby.backToLobby) { self.panel = nil }
                    .buttonStyle(OutlinedButtonStyle())
                    .padding(.top, 8)
                    .accessibilityIdentifier(TestIds.lobbyDetailBack)
            }
            .container(TestIds.lobbyDetail)
        case .promo(let n):
            PanelColumn {
                Text(Lobby.bannerTitles[n - 1]).font(.title2.weight(.semibold)).multilineTextAlignment(.center)
                Text(Lobby.pagerPosition(n)).font(.subheadline.weight(.medium))
                Text(Lobby.promoNote).font(.body).multilineTextAlignment(.center)
                Button(Lobby.backToLobby) { self.panel = nil }
                    .buttonStyle(OutlinedButtonStyle())
                    .padding(.top, 8)
                    .accessibilityIdentifier(TestIds.lobbyPromoBack)
            }
            .container(TestIds.lobbyPromo)
        case .saved:
            PanelColumn {
                Art.icon("check").resizable().frame(width: 40, height: 40).foregroundStyle(Color(Palette.onSurfaceVariant))
                    .accessibilityHidden(true)
                Text(Lobby.savedEmpty).font(.title3.weight(.semibold))
            }
            .screen(TestIds.lobbySavedScreen)
        }
    }

    // MARK: Actions

    /// A delay choice restarts the count, so a scenario that chooses 12 s gets 12 s from its choice.
    private func choose(_ seconds: Int) {
        model.lobbySavedDelay = seconds
        savedArrived = false
        clockStart = .now
    }

    /// The top bar's Back: closes the detail or the promo, and leaves the Lobby otherwise.
    private func closePanel() -> Bool {
        guard let panel, panel.closesWithBack else { return false }
        self.panel = nil
        return true
    }
}

// MARK: The touch

extension View {
    /// SwiftUI's own double tap, tap and long press, in that order, so a tap waits for the double-tap time to pass. The
    /// element is one accessibility node with its id and its label; it has no child with an id of its own.
    func lobbyTouch(_ label: String, id: String, log: Binding<TouchLog>, place: String,
                    onTap: @escaping () -> Void = {}, onLongPress: @escaping () -> Void = {}) -> some View {
        contentShape(Rectangle())
            .onTapGesture(count: 2) { log.wrappedValue.add(.doubleTap, label, place) }
            .onTapGesture {
                log.wrappedValue.add(.tap, label, place)
                onTap()
            }
            .onLongPressGesture {
                log.wrappedValue.add(.longPress, label, place)
                onLongPress()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier(id)
    }
}

// MARK: The fixed parts

private struct TouchLogBlock: View {
    @Binding var log: TouchLog

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Lobby.touchLogLabel).font(.caption.weight(.medium)).foregroundStyle(Color(Palette.onSurfaceVariant))
                Text(log.text)
                    .font(.footnote)
                    .foregroundStyle(Color(Palette.onSurface))
                    .lineLimit(3, reservesSpace: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier(TestIds.lobbyTouchLog)
            }
            VStack(alignment: .trailing, spacing: 0) {
                Text(log.countText)
                    .font(.caption.weight(.medium))
                    .monospacedDigit()
                    .accessibilityIdentifier(TestIds.lobbyTouchCount)
                Button(Lobby.reset) { log.reset() }
                    .font(.subheadline.weight(.semibold))
                    .frame(minHeight: 36)
                    .accessibilityIdentifier(TestIds.lobbyTouchReset)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(Color(Palette.surfaceContainerLow))
    }
}

/// A switch whose whole row is the target, as the form's newsletter switch: a tap anywhere on it turns it, and to
/// Appium and VoiceOver it is the system's switch with its value.
struct LobbySwitch: View {
    let title: String
    let isOn: Bool
    let id: String
    let set: (Bool) -> Void

    var body: some View {
        Button { set(!isOn) } label: {
            HStack(spacing: 8) {
                Text(title).font(.subheadline.weight(.medium)).foregroundStyle(Color(Palette.onSurface))
                Toggle("", isOn: .constant(isOn)).labelsHidden().allowsHitTesting(false).accessibilityHidden(true)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation { Toggle(title, isOn: Binding(get: { isOn }, set: set)) }
        .accessibilityIdentifier(id)
    }
}

private struct DelayChoice: View {
    let delay: Int
    let pagerShown: Bool
    let choose: (Int) -> Void
    let showPager: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(Lobby.savedAppearsAfter).font(.caption.weight(.medium)).foregroundStyle(Color(Palette.onSurfaceVariant))
                Spacer()
                LobbySwitch(title: Lobby.showThePager, isOn: pagerShown, id: TestIds.lobbyPagerShown, set: showPager)
            }
            HStack(spacing: 0) {
                ForEach(Lobby.delays, id: \.self) { seconds in
                    let on = seconds == delay
                    Button { choose(seconds) } label: {
                        Text(Lobby.delayLabel(seconds))
                            .font(.subheadline.weight(on ? .bold : .regular))
                            .foregroundStyle(on ? Color(Palette.onSecondaryContainer) : Color(Palette.onSurface))
                            .frame(maxWidth: .infinity, minHeight: 36)
                            .background(on ? Color(Palette.secondaryContainer) : Color.clear)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                    .accessibilityIdentifier(TestIds.lobbySavedDelayChoice(seconds))
                    if seconds != Lobby.delays.last {
                        Color(Palette.outline).frame(width: 1, height: 36).accessibilityHidden(true)
                    }
                }
            }
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color(Palette.outline), lineWidth: 1))
            .container(TestIds.lobbySavedDelay)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

private struct PagerBlock: View {
    @Binding var banner: Int?
    @Binding var auto: Bool
    @Binding var log: TouchLog
    let onPromo: (Int) -> Void
    let onSheet: (LobbySheetTarget) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(1...Lobby.banners, id: \.self) { n in
                        bannerView(n)
                            .padding(.horizontal, 16)
                            .containerRelativeFrame(.horizontal)
                            .id(n)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $banner)
            .scrollIndicators(.hidden)
            .frame(height: 100)
            .padding(.top, 4)
            .scrollingList(TestIds.lobbyPager)
            HStack {
                let position = Lobby.pagerPosition(banner ?? 1)
                HStack(spacing: 6) {
                    ForEach(1...Lobby.banners, id: \.self) { n in
                        let on = n == (banner ?? 1)
                        Circle()
                            .fill(on ? Color(Palette.primary) : Color(Palette.outlineVariant))
                            .frame(width: on ? 10 : 6, height: on ? 10 : 6)
                    }
                    Text(position).font(.caption.weight(.medium)).padding(.leading, 4)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(position)
                .accessibilityIdentifier(TestIds.lobbyPagerPosition)
                Spacer()
                LobbySwitch(title: Lobby.autoAdvance, isOn: auto, id: TestIds.lobbyPagerAuto) { auto = $0 }
            }
            .padding(.horizontal, 16)
        }
        .task(id: auto) {
            while auto {
                try? await Task.sleep(for: .seconds(Lobby.autoAdvanceSeconds))
                if Task.isCancelled || !auto { return }
                withAnimation { banner = (banner ?? 1) % Lobby.banners + 1 }
            }
        }
    }

    private func bannerView(_ n: Int) -> some View {
        let title = Lobby.bannerTitles[n - 1]
        return VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline).foregroundStyle(Color(Palette.onPrimaryContainer))
            Text(Lobby.testBanner).font(.footnote).foregroundStyle(Color(Palette.onPrimaryContainer))
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(Palette.primaryContainer), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .lobbyTouch(title, id: TestIds.lobbyBanner(n), log: $log, place: "banner \(n)",
                    onTap: { onPromo(n) }, onLongPress: { onSheet(LobbySheetTarget(title: title, opens: .promo(n))) })
    }
}

/// The Top 10 row (SPEC.md §5, 1.1): fixed, outside the page, under the pager or in its place. No vertical scroller
/// encloses it: the row of run `00ec77f5`.
private struct TopRow: View {
    @Binding var log: TouchLog
    let onDetail: (Int) -> Void
    let onSheet: (LobbySheetTarget) -> Void
    @State private var offset = 0.0
    @State private var width = 393.0

    var body: some View {
        let range = Lobby.fullyVisible(offset: offset, viewport: width, count: Lobby.topTiles)
        let position = Lobby.topRowPosition(first: range.first, last: range.last)
        VStack(alignment: .leading, spacing: 4) {
            Text(position)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(Palette.primary))
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel(position)
                .accessibilityIdentifier(TestIds.lobbyTopRowPosition)
            ScrollView(.horizontal) {
                LazyHStack(spacing: Lobby.tileSpacing) {
                    ForEach(1...Lobby.topTiles, id: \.self) { tile in
                        tileView(tile)
                    }
                }
                .padding(.horizontal, Lobby.rowInset)
                .padding(.bottom, 4)
                .onGeometryChange(for: Double.self) { -$0.frame(in: .scrollView).minX } action: { offset = $0 }
            }
            .scrollIndicators(.hidden)
            .onGeometryChange(for: Double.self) { $0.size.width } action: { width = $0 }
            .scrollingList(TestIds.lobbyTopRow)
        }
    }

    private func tileView(_ tile: Int) -> some View {
        let item = Lobby.topItem(tile)
        return VStack(alignment: .leading, spacing: 4) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(Palette.tile(item.aisle)))
                .frame(width: Lobby.tileWidth, height: Lobby.topBandHeight)
                .overlay {
                    Art.glyph(item.glyph).resizable().scaledToFit()
                        .foregroundStyle(Color(Palette.ink(item.aisle)))
                        .frame(width: 40, height: 40)
                }
            Text(item.name).font(.caption).lineLimit(1).foregroundStyle(Color(Palette.onSurface))
        }
        .frame(width: Lobby.tileWidth)
        .lobbyTouch(item.name, id: TestIds.lobbyTopRowTile(tile), log: $log, place: Lobby.tileWhere(row: Lobby.topRow, tile: tile),
                    onTap: { onDetail(tile) },
                    onLongPress: { onSheet(LobbySheetTarget(title: item.name, opens: .detail(row: Lobby.topRow, tile: tile))) })
    }
}

// MARK: The page

private struct LobbyPage: View {
    @Binding var log: TouchLog
    @Binding var chip: Int
    let onDetail: (Int, Int) -> Void
    let onSheet: (LobbySheetTarget) -> Void

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 0) {
                chips
                ForEach(1...Lobby.rows, id: \.self) { row in
                    TileRow(row: row, log: $log, onDetail: onDetail, onSheet: onSheet)
                }
                grid
                innerList
                LobbyBoard(log: $log)
                VStack(spacing: 4) {
                    Text(Lobby.footer).font(.headline)
                    Text(Lobby.footerNote).font(.footnote).foregroundStyle(Color(Palette.onSurfaceVariant))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
                .padding(.bottom, 48)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier(TestIds.lobbyFooter)
            }
        }
        .scrollingList(TestIds.lobbyPage)
    }

    private var chips: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 8) {
                ForEach(1...Lobby.chips.count, id: \.self) { n in
                    let label = Lobby.chips[n - 1]
                    let on = n == chip
                    HStack(spacing: 6) {
                        if on { Art.icon("check").resizable().frame(width: 16, height: 16) }
                        Text(label).font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(on ? Color(Palette.onSecondaryContainer) : Color(Palette.onSurface))
                    .padding(.horizontal, 12)
                    .frame(minHeight: 32)
                    .background(on ? Color(Palette.secondaryContainer) : Color(Palette.surface), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(on ? Color(Palette.secondaryContainer) : Color(Palette.outline), lineWidth: 1))
                    .lobbyTouch(label, id: TestIds.lobbyChip(n), log: $log, place: "chip \(n)", onTap: { chip = n })
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .scrollIndicators(.hidden)
        .scrollingList(TestIds.lobbyChips)
    }

    private var grid: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeading(Lobby.grid)
            VStack(spacing: 8) {
                ForEach(0..<(Lobby.gridCells / 2), id: \.self) { r in
                    HStack(spacing: 8) {
                        ForEach(1...2, id: \.self) { c in
                            let n = r * 2 + c
                            let item = Lobby.gridItem(n)
                            HStack(spacing: 8) {
                                GlyphTile(item: item, size: 40)
                                Text(item.name).font(.footnote).lineLimit(2).foregroundStyle(Color(Palette.onSurface))
                                Spacer(minLength: 0)
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(Palette.outlineVariant), lineWidth: 1))
                            .lobbyTouch(item.name, id: TestIds.lobbyGridCell(n), log: $log, place: "grid, cell \(n)")
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .container(TestIds.lobbyGrid)
        }
    }

    private var innerList: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeading(Lobby.innerList)
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(1...Lobby.innerLines, id: \.self) { n in
                        VStack(spacing: 0) {
                            Text(Lobby.innerLine(n)).font(.body).foregroundStyle(Color(Palette.onSurface))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                            Color(Palette.outlineVariant).frame(height: 0.5)
                        }
                        .lobbyTouch(Lobby.innerLine(n), id: TestIds.lobbyInnerRow(n), log: $log, place: "inner list")
                    }
                }
            }
            .frame(height: Lobby.innerListHeight)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(Palette.outlineVariant), lineWidth: 1))
            .padding(.horizontal, 16)
            .scrollingList(TestIds.lobbyInnerList)
        }
    }
}

private struct SectionHeading: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color(Palette.primary))
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .accessibilityAddTraits(.isHeader)
    }
}

/// A row of 20 tiles in the page, with its position line above it.
private struct TileRow: View {
    let row: Int
    @Binding var log: TouchLog
    let onDetail: (Int, Int) -> Void
    let onSheet: (LobbySheetTarget) -> Void
    @State private var offset = 0.0
    @State private var width = 393.0

    var body: some View {
        let range = Lobby.fullyVisible(offset: offset, viewport: width, count: Lobby.tiles)
        let position = Lobby.rowPosition(row: row, first: range.first, last: range.last)
        VStack(alignment: .leading, spacing: 8) {
            Text(position)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(Palette.primary))
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel(position)
                .accessibilityIdentifier(TestIds.lobbyRowPosition(row))
            ScrollView(.horizontal) {
                LazyHStack(spacing: Lobby.tileSpacing) {
                    ForEach(1...Lobby.tiles, id: \.self) { tile in
                        tileView(tile)
                    }
                }
                .padding(.horizontal, Lobby.rowInset)
                .onGeometryChange(for: Double.self) { -$0.frame(in: .scrollView).minX } action: { offset = $0 }
            }
            .scrollIndicators(.hidden)
            .onGeometryChange(for: Double.self) { $0.size.width } action: { width = $0 }
            .scrollingList(TestIds.lobbyRow(row))
        }
    }

    private func tileView(_ tile: Int) -> some View {
        let item = Lobby.tileItem(row: row, tile: tile)
        return VStack(alignment: .leading, spacing: 4) {
            GlyphTile(item: item, size: Lobby.tileWidth)
            Text(item.name).font(.caption).lineLimit(1).foregroundStyle(Color(Palette.onSurface))
            ItemNumber(item: item)
        }
        .frame(width: Lobby.tileWidth)
        .lobbyTouch(item.name, id: TestIds.lobbyRowTile(row, tile), log: $log, place: Lobby.tileWhere(row: row, tile: tile),
                    onTap: { onDetail(row, tile) },
                    onLongPress: { onSheet(LobbySheetTarget(title: item.name, opens: .detail(row: row, tile: tile))) })
    }
}

/// The board: one `ScrollView([.horizontal, .vertical])` onto 26 × 26 cells, 280 points square.
private struct LobbyBoard: View {
    @Binding var log: TouchLog
    @State private var x = 0.0
    @State private var y = 0.0

    var body: some View {
        let corner = Lobby.boardTopLeft(x: x, y: y)
        let position = Lobby.boardPosition(col: corner.col, row: corner.row)
        VStack(alignment: .leading, spacing: 8) {
            Text(position)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(Palette.primary))
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel(position)
                .accessibilityIdentifier(TestIds.lobbyBoardPosition)
            ScrollView([.horizontal, .vertical]) {
                LazyVStack(spacing: 0) {
                    ForEach(1...Lobby.board, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(1...Lobby.board, id: \.self) { col in
                                cell(col: col, row: row)
                            }
                        }
                    }
                }
                .onGeometryChange(for: CGPoint.self) { proxy in
                    let frame = proxy.frame(in: .scrollView)
                    return CGPoint(x: -frame.minX, y: -frame.minY)
                } action: { point in
                    x = point.x
                    y = point.y
                }
            }
            .scrollIndicators(.hidden)
            .frame(width: Lobby.boardSide, height: Lobby.boardSide)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(Palette.outline), lineWidth: 1))
            .scrollingList(TestIds.lobbyBoard)
            .frame(maxWidth: .infinity)
        }
    }

    private func cell(col: Int, row: Int) -> some View {
        let label = Lobby.boardLabel(col: col, row: row)
        return Text(label)
            .font(.caption.weight(.medium))
            .foregroundStyle(Color(Palette.onSurface))
            .frame(width: Lobby.boardCell, height: Lobby.boardCell)
            .border(Color(Palette.outlineVariant), width: 0.5)
            .lobbyTouch(label, id: TestIds.lobbyBoardCell(Lobby.columnKey(col), row), log: $log, place: "board")
    }
}

// MARK: Panels and the sheet

private struct PanelColumn<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 8) { content }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// The quick sheet: SwiftUI's own sheet at the medium detent, a layer of its own over the Lobby. Its title and four
/// buttons stay put; under them, More like this (1.2) is the sheet's own `ScrollView`, which fills the rest of the
/// detent, so its 20 lines run past the sheet's foot and come only by scrolling inside it.
private struct QuickSheet: View {
    let target: LobbySheetTarget
    let tapped: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(target.title)
                .font(.title3.weight(.semibold))
                .padding(.bottom, 8)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier(TestIds.lobbySheetTitle)
            sheetButton("Open", id: TestIds.lobbySheetOpen)
            sheetButton("Preview", id: TestIds.lobbySheetPreview)
            sheetButton("Saved", id: TestIds.lobbySheetSaved)
            sheetButton("Rate", id: TestIds.lobbySheetRate)
            Text(Lobby.moreLikeThis)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(Palette.primary))
                .padding(.top, 8)
                .accessibilityAddTraits(.isHeader)
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(1...Lobby.sheetMoreLines, id: \.self) { n in
                        moreLine(n)
                    }
                }
            }
            .scrollingList(TestIds.lobbySheetMore)
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .container(TestIds.lobbySheet)
    }

    private func sheetButton(_ label: String, id: String) -> some View {
        Button { tapped(label) } label: {
            Text(label).font(.body).frame(maxWidth: .infinity, minHeight: 48, alignment: .leading).contentShape(Rectangle())
        }
        .accessibilityIdentifier(id)
    }

    /// A line of More like this: touched as a button is, so a tap is logged and closes the sheet.
    private func moreLine(_ n: Int) -> some View {
        let line = Lobby.sheetMoreLine(title: target.title, n)
        return Button { tapped(line) } label: {
            VStack(spacing: 0) {
                Text(line)
                    .font(.body)
                    .foregroundStyle(Color(Palette.onSurface))
                    .frame(maxWidth: .infinity, minHeight: Lobby.sheetLineHeight - 0.5, alignment: .leading)
                Color(Palette.outlineVariant).frame(height: 0.5)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(line)
        .accessibilityIdentifier(TestIds.lobbySheetMoreRow(n))
    }
}

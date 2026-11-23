import MossgroveKit
import SwiftUI

/// What the Feed holds while it is shown: the kit's rule (`FeedState`), observed by the view. The screen makes its own;
/// a test hands one in and reads it. Only the main thread touches it: the view, and FeedViewTests.
@Observable
final class FeedModel {
    private(set) var state = FeedState()

    /// Rows up to `lastShown` show: a load starts when the third row from the end of what has come is among them.
    func shown(upTo lastShown: Int) { _ = state.shown(upTo: lastShown) }

    /// The load's second has passed: the spinner row goes and 20 more rows come.
    func loaded() { state.loaded() }
}

/// The Feed (SPEC.md §5, new in 1.2): a list that never ends. A `ScrollView` with a `LazyVStack` of rows that are all
/// the same height, so the rows that show follow from the scroll offset alone. When the third row from the end of what
/// has come shows, a spinner row comes after the last row; 1 s later it goes and 20 more rows come in its place.
struct FeedView: View {
    @State private var model: FeedModel
    @State private var offset = 0.0
    @State private var viewport = 0.0
    /// 56 points at the default text size, larger with a larger font: every row the same, so the arithmetic holds.
    @ScaledMetric(relativeTo: .body) private var rowHeight = Feed.rowHeight

    init(model: FeedModel = FeedModel()) {
        _model = State(initialValue: model)
    }

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(1...model.state.count, id: \.self) { n in
                    row(n)
                }
                if model.state.loading {
                    loadingRow
                }
            }
            .onGeometryChange(for: Double.self) { -$0.frame(in: .scrollView).minY } action: { value in
                offset = value
                check()
            }
        }
        .onGeometryChange(for: Double.self) { $0.size.height } action: { value in
            viewport = value
            check()
        }
        .scrollingList(TestIds.feedList)
        .screenBackground()
        .screen(TestIds.feedScreen)
        .topBar(Feed.title, back: true)
        .onAppear(perform: check)
        .task(id: model.state.loading) {
            guard model.state.loading else { return }
            try? await Task.sleep(for: .seconds(Feed.loadSeconds))
            if Task.isCancelled { return }
            model.loaded()
            // the new third row from the end may already show (a tall screen): the next load starts at once
            check()
        }
    }

    /// Starts a load when the third row from the end of what has come shows.
    private func check() {
        model.shown(upTo: Feed.lastShown(offset: offset, viewport: viewport, rowHeight: rowHeight, count: model.state.count))
    }

    private func row(_ n: Int) -> some View {
        VStack(spacing: 0) {
            Text(Feed.row(n))
                .font(.body)
                .foregroundStyle(Color(Palette.onSurface))
                .lineLimit(1)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            Color(Palette.outlineVariant).frame(height: 0.5)
        }
        .frame(height: rowHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Feed.row(n))
        .accessibilityIdentifier(TestIds.feedRow(n))
    }

    private var loadingRow: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text(Feed.loading).font(.body).foregroundStyle(Color(Palette.onSurfaceVariant))
        }
        .frame(maxWidth: .infinity, minHeight: rowHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Feed.loading)
        .accessibilityIdentifier(TestIds.feedLoading)
    }
}

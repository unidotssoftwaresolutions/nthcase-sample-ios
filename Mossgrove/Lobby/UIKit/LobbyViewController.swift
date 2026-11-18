import MossgroveKit
import UIKit

/// Lobby (UIKit), the Lobby built a second time with UIKit (SPEC.md §5 and §12, new in 1.1).
///
/// Top to bottom, as subviews in that order: the touch log, "Saved appears after" with Show the pager, the pager (its
/// own `UICollectionView`, horizontal and paging, removed from its superview while Show the pager is off), the Top 10
/// row (its own horizontal `UICollectionView`), the page, and the bar (a `UIStackView` of buttons). The page is one
/// `UICollectionView` with a compositional layout: the chips and the four tile rows are sections that scroll
/// orthogonally, the grid is one cell holding a view of 2 × 6 cells (a section has no view of its own to carry
/// `lobby_grid`), the inner list is a `UITableView` 240 points high in a cell, and the board
/// is a `UIScrollView` whose content is wider and taller than its frame. The quick sheet is a view controller with
/// `UISheetPresentationController` at the medium detent.
final class LobbyViewController: UIViewController {
    private let model: AppModel
    private var log = TouchLog() { didSet { renderLog() } }
    private var panel: LobbyPanel? { didSet { renderPanel() } }
    private var barSelected = "Home"
    private var chip = 1
    private var banner = 1
    private var autoTask: Task<Void, Never>?
    private var savedTask: Task<Void, Never>?

    private enum Section: Int, CaseIterable { case chips, row1, row2, row3, row4, grid, inner, board, footer }

    // The fixed parts
    private let logLabel = lobbyLabel(.footnote)
    private let countLabel = lobbyLabel(.caption1, weight: .medium)
    private let resetButton = UIButton(type: .system)
    private var delayButtons: [Int: UIButton] = [:]
    private let delayRow = UIStackView()
    private let pagerSwitch = SwitchRow(title: Lobby.showThePager, id: TestIds.lobbyPagerShown)
    private let autoSwitch = SwitchRow(title: Lobby.autoAdvance, id: TestIds.lobbyPagerAuto)
    private let pagerFrame = UIStackView()
    private let pagerPosition = UIView()
    private let pagerPositionLabel = lobbyLabel(.caption1, weight: .medium)
    private var dots: [UIView] = []
    private let topPositionLabel = lobbyLabel(.subheadline, weight: .semibold, color: Palette.primary)
    private let lobbyStack = UIStackView()
    private let panelHost = UIView()
    private let bar = UIStackView()
    private var barButtons: [String: UIButton] = [:]

    // The scrollers
    private lazy var pager = UICollectionView(frame: .zero, collectionViewLayout: Self.horizontalLayout(width: .fractionalWidth(1), height: 100, spacing: 0, inset: 0))
    private lazy var topRow = UICollectionView(frame: .zero, collectionViewLayout: Self.horizontalLayout(
        width: .absolute(Lobby.tileWidth), height: 92, spacing: Lobby.tileSpacing, inset: Lobby.rowInset))
    private lazy var page = UICollectionView(frame: .zero, collectionViewLayout: pageLayout())
    private let innerList = UITableView(frame: .zero, style: .plain)
    private lazy var board = BoardView { TestIds.lobbyBoardCell(Lobby.columnKey($0), $1) }
    private let footer = UIStackView()
    private let grid = UIStackView()
    /// The orthogonal scrollers UIKit makes for the chip and tile sections, by section, once each has been seen.
    private var rowScrollers: [Int: NSKeyValueObservation] = [:]
    private var rowRanges: [Int: (first: Int, last: Int)] = [:]
    private var boardCorner = (col: 1, row: 1)

    init(model: AppModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("not from a storyboard") }

    deinit {
        autoTask?.cancel()
        savedTask?.cancel()
    }

    // MARK: Building

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.surface
        view.accessibilityIdentifier = TestIds.lobbyScreen

        let root = UIStackView(arrangedSubviews: [logBlock(), delayBlock(), contentArea(), barBlock()])
        root.axis = .vertical
        root.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(root)
        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            root.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
        let barBackground = UIView()
        barBackground.backgroundColor = Palette.surfaceContainer
        barBackground.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(barBackground, at: 0)
        NSLayoutConstraint.activate([
            barBackground.topAnchor.constraint(equalTo: bar.topAnchor),
            barBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            barBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            barBackground.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // CGColor borders do not follow the theme by themselves
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (lobby: LobbyViewController, _: UITraitCollection) in
            lobby.renderDelay()
            lobby.innerList.layer.borderColor = Palette.outlineVariant.resolvedColor(with: lobby.traitCollection).cgColor
            lobby.page.reconfigureItems(at: lobby.page.indexPathsForVisibleItems)
        }
        renderLog()
        renderDelay()
        renderPagerShown()
        renderPanel()
        restartClock()
    }

    private func logBlock() -> UIView {
        let heading = lobbyLabel(.caption1, weight: .medium, color: Palette.onSurfaceVariant)
        heading.text = Lobby.touchLogLabel
        logLabel.numberOfLines = 3
        logLabel.accessibilityIdentifier = TestIds.lobbyTouchLog
        countLabel.accessibilityIdentifier = TestIds.lobbyTouchCount
        resetButton.setTitle(Lobby.reset, for: .normal)
        resetButton.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        resetButton.tintColor = Palette.primary
        resetButton.accessibilityIdentifier = TestIds.lobbyTouchReset
        resetButton.addAction(UIAction { [weak self] _ in self?.log.reset() }, for: .touchUpInside)
        // three lines of room, so the screen below does not move as the log grows
        let logHeight = logLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: logLabel.font.lineHeight * 3)
        logHeight.isActive = true
        let left = UIStackView(arrangedSubviews: [heading, logLabel])
        left.axis = .vertical
        left.spacing = 2
        let right = UIStackView(arrangedSubviews: [countLabel, resetButton])
        right.axis = .vertical
        right.alignment = .trailing
        let row = UIStackView(arrangedSubviews: [left, right])
        row.alignment = .top
        row.spacing = 8
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16)
        row.backgroundColor = Palette.surfaceContainerLow
        left.setContentHuggingPriority(.defaultLow, for: .horizontal)
        right.setContentHuggingPriority(.required, for: .horizontal)
        return row
    }

    private func delayBlock() -> UIView {
        let heading = lobbyLabel(.caption1, weight: .medium, color: Palette.onSurfaceVariant)
        heading.text = Lobby.savedAppearsAfter
        pagerSwitch.toggle.addAction(UIAction { [weak self] action in
            guard let self, let toggle = action.sender as? UISwitch else { return }
            model.lobbyPagerShown = toggle.isOn
            renderPagerShown()
        }, for: .valueChanged)
        let line = UIStackView(arrangedSubviews: [heading, UIView(), pagerSwitch])
        line.alignment = .center
        for seconds in Lobby.delays {
            let button = UIButton(type: .custom)
            button.setTitle(Lobby.delayLabel(seconds), for: .normal)
            button.accessibilityIdentifier = TestIds.lobbySavedDelayChoice(seconds)
            button.addAction(UIAction { [weak self] _ in self?.choose(seconds) }, for: .touchUpInside)
            button.heightAnchor.constraint(equalToConstant: 36).isActive = true
            delayButtons[seconds] = button
            delayRow.addArrangedSubview(button)
        }
        delayRow.distribution = .fillEqually
        delayRow.layer.cornerRadius = 18
        delayRow.layer.borderWidth = 1
        delayRow.clipsToBounds = true
        delayRow.accessibilityIdentifier = TestIds.lobbySavedDelay
        let block = UIStackView(arrangedSubviews: [line, delayRow])
        block.axis = .vertical
        block.spacing = 4
        block.isLayoutMarginsRelativeArrangement = true
        block.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
        return block
    }

    private func contentArea() -> UIView {
        // the pager and its position line, one frame removed and put back as a whole
        pager.isPagingEnabled = true
        pager.showsHorizontalScrollIndicator = false
        pager.backgroundColor = .clear
        pager.allowsSelection = false
        pager.dataSource = self
        pager.delegate = self
        pager.register(BannerCell.self, forCellWithReuseIdentifier: BannerCell.reuse)
        pager.accessibilityIdentifier = TestIds.lobbyPager
        pager.heightAnchor.constraint(equalToConstant: 100).isActive = true
        for _ in 1...Lobby.banners {
            let dot = UIView()
            dot.layer.cornerRadius = 5
            dot.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([dot.widthAnchor.constraint(equalToConstant: 10), dot.heightAnchor.constraint(equalToConstant: 10)])
            dots.append(dot)
        }
        let dotRow = UIStackView(arrangedSubviews: dots + [pagerPositionLabel])
        dotRow.spacing = 6
        dotRow.alignment = .center
        dotRow.translatesAutoresizingMaskIntoConstraints = false
        pagerPosition.addSubview(dotRow)
        NSLayoutConstraint.activate([
            dotRow.leadingAnchor.constraint(equalTo: pagerPosition.leadingAnchor), dotRow.trailingAnchor.constraint(equalTo: pagerPosition.trailingAnchor),
            dotRow.topAnchor.constraint(equalTo: pagerPosition.topAnchor), dotRow.bottomAnchor.constraint(equalTo: pagerPosition.bottomAnchor),
        ])
        pagerPosition.isAccessibilityElement = true
        pagerPosition.accessibilityIdentifier = TestIds.lobbyPagerPosition
        autoSwitch.toggle.addAction(UIAction { [weak self] action in
            guard let toggle = action.sender as? UISwitch else { return }
            self?.setAuto(toggle.isOn)
        }, for: .valueChanged)
        let positionLine = UIStackView(arrangedSubviews: [pagerPosition, UIView(), autoSwitch])
        positionLine.alignment = .center
        positionLine.isLayoutMarginsRelativeArrangement = true
        positionLine.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        pagerFrame.addArrangedSubview(pager)
        pagerFrame.addArrangedSubview(positionLine)
        pagerFrame.axis = .vertical
        pagerFrame.spacing = 4
        pagerFrame.isLayoutMarginsRelativeArrangement = true
        pagerFrame.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 0)

        // the Top 10 row
        topPositionLabel.accessibilityIdentifier = TestIds.lobbyTopRowPosition
        topPositionLabel.accessibilityTraits = .header
        let topHeading = UIStackView(arrangedSubviews: [topPositionLabel])
        topHeading.isLayoutMarginsRelativeArrangement = true
        topHeading.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16)
        topRow.showsHorizontalScrollIndicator = false
        topRow.backgroundColor = .clear
        topRow.allowsSelection = false
        topRow.dataSource = self
        topRow.delegate = self
        topRow.register(TopTileCell.self, forCellWithReuseIdentifier: TopTileCell.reuse)
        topRow.accessibilityIdentifier = TestIds.lobbyTopRow
        topRow.heightAnchor.constraint(equalToConstant: 96).isActive = true

        // the page
        page.backgroundColor = .clear
        page.allowsSelection = false
        page.dataSource = self
        page.delegate = self
        page.register(TileCell.self, forCellWithReuseIdentifier: TileCell.reuse)
        page.register(ChipCell.self, forCellWithReuseIdentifier: ChipCell.reuse)
        page.register(HostCell.self, forCellWithReuseIdentifier: HostCell.reuse)
        page.register(HeadingView.self, forSupplementaryViewOfKind: HeadingView.kind, withReuseIdentifier: HeadingView.reuse)
        page.accessibilityIdentifier = TestIds.lobbyPage
        buildGrid()
        buildInnerList()
        buildBoard()
        buildFooter()

        lobbyStack.axis = .vertical
        lobbyStack.addArrangedSubview(topHeading)
        lobbyStack.addArrangedSubview(topRow)
        lobbyStack.addArrangedSubview(page)
        lobbyStack.translatesAutoresizingMaskIntoConstraints = false
        panelHost.translatesAutoresizingMaskIntoConstraints = false
        let area = UIView()
        area.addSubview(lobbyStack)
        area.addSubview(panelHost)
        for child in [lobbyStack, panelHost] {
            NSLayoutConstraint.activate([
                child.topAnchor.constraint(equalTo: area.topAnchor), child.bottomAnchor.constraint(equalTo: area.bottomAnchor),
                child.leadingAnchor.constraint(equalTo: area.leadingAnchor), child.trailingAnchor.constraint(equalTo: area.trailingAnchor),
            ])
        }
        area.setContentHuggingPriority(.defaultLow, for: .vertical)
        return area
    }

    private func buildGrid() {
        grid.axis = .vertical
        grid.spacing = 8
        for r in 0..<(Lobby.gridCells / 2) {
            let line = UIStackView()
            line.spacing = 8
            line.distribution = .fillEqually
            for c in 1...2 {
                let n = r * 2 + c
                let item = Lobby.gridItem(n)
                let cell = GridCellView(item: item)
                cell.accessibilityIdentifier = TestIds.lobbyGridCell(n)
                cell.touched = { [weak self] touch in self?.log.add(touch, item.name, "grid, cell \(n)") }
                line.addArrangedSubview(cell)
            }
            grid.addArrangedSubview(line)
        }
        grid.accessibilityIdentifier = TestIds.lobbyGrid
    }

    private func buildInnerList() {
        innerList.dataSource = self
        innerList.delegate = self
        innerList.register(InnerLineCell.self, forCellReuseIdentifier: InnerLineCell.reuse)
        innerList.rowHeight = 48
        innerList.backgroundColor = .clear
        innerList.separatorColor = Palette.outlineVariant
        innerList.layer.cornerRadius = 8
        innerList.layer.borderWidth = 1
        innerList.layer.borderColor = Palette.outlineVariant.resolvedColor(with: traitCollection).cgColor
        innerList.accessibilityIdentifier = TestIds.lobbyInnerList
    }

    private func buildBoard() {
        board.delegate = self
        board.accessibilityIdentifier = TestIds.lobbyBoard
        board.touched = { [weak self] touch, label in self?.log.add(touch, label, "board") }
    }

    private func buildFooter() {
        let title = lobbyLabel(.headline)
        title.text = Lobby.footer
        let note = lobbyLabel(.footnote, color: Palette.onSurfaceVariant)
        note.text = Lobby.footerNote
        footer.addArrangedSubview(title)
        footer.addArrangedSubview(note)
        footer.axis = .vertical
        footer.alignment = .center
        footer.spacing = 4
        footer.isLayoutMarginsRelativeArrangement = true
        footer.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 24, leading: 16, bottom: 48, trailing: 16)
        footer.isAccessibilityElement = true
        footer.accessibilityLabel = "\(Lobby.footer), \(Lobby.footerNote)"
        footer.accessibilityIdentifier = TestIds.lobbyFooter
    }

    private func barBlock() -> UIView {
        for (label, id) in [("Home", TestIds.lobbyBarHome), ("Live", TestIds.lobbyBarLive), ("Saved", TestIds.lobbyBarSaved),
                            ("Offers", TestIds.lobbyBarOffers)] {
            var configuration = UIButton.Configuration.plain()
            configuration.image = Art.uiIcon(LobbyArt.barIcon(label))
            configuration.imagePlacement = .top
            configuration.imagePadding = 2
            configuration.title = label
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
                var attributes = attributes
                attributes.font = .preferredFont(forTextStyle: .caption2)
                return attributes
            }
            let button = UIButton(configuration: configuration)
            button.accessibilityIdentifier = id
            button.accessibilityLabel = label
            button.addAction(UIAction { [weak self] _ in self?.barTapped(label) }, for: .touchUpInside)
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 52).isActive = true
            barButtons[label] = button
            bar.addArrangedSubview(button)
        }
        bar.distribution = .fillEqually
        bar.accessibilityIdentifier = TestIds.lobbyBar
        renderBar()
        return bar
    }

    // MARK: Layouts

    /// A horizontal list: the pager (one page a screen wide) and the Top 10 row (tiles 100 wide).
    private static func horizontalLayout(width: NSCollectionLayoutDimension, height: CGFloat, spacing: CGFloat, inset: CGFloat) -> UICollectionViewLayout {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: width, heightDimension: .absolute(height)))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: item.layoutSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = spacing
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: inset, bottom: 0, trailing: inset)
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.scrollDirection = .horizontal
        return UICollectionViewCompositionalLayout(section: section, configuration: configuration)
    }

    private func pageLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { index, _ in
            let heading = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(44)),
                elementKind: HeadingView.kind, alignment: .top)
            func full(_ height: CGFloat) -> NSCollectionLayoutSection {
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(height)))
                return NSCollectionLayoutSection(group: .vertical(layoutSize: item.layoutSize, subitems: [item]))
            }
            switch Section(rawValue: index)! {
            case .chips:
                let size = NSCollectionLayoutSize(widthDimension: .estimated(80), heightDimension: .absolute(36))
                let section = NSCollectionLayoutSection(group: .horizontal(layoutSize: size, subitems: [NSCollectionLayoutItem(layoutSize: size)]))
                section.orthogonalScrollingBehavior = .continuous
                section.interGroupSpacing = 8
                section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
                return section
            case .row1, .row2, .row3, .row4:
                let size = NSCollectionLayoutSize(widthDimension: .absolute(Lobby.tileWidth), heightDimension: .absolute(146))
                let section = NSCollectionLayoutSection(group: .horizontal(layoutSize: size, subitems: [NSCollectionLayoutItem(layoutSize: size)]))
                section.orthogonalScrollingBehavior = .continuous
                section.interGroupSpacing = Lobby.tileSpacing
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: Lobby.rowInset, bottom: 0, trailing: Lobby.rowInset)
                section.boundarySupplementaryItems = [heading]
                return section
            case .grid:
                let section = full(Double(Lobby.gridCells / 2) * 64 - 8)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
                section.boundarySupplementaryItems = [heading]
                return section
            case .inner:
                let section = full(Lobby.innerListHeight)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
                section.boundarySupplementaryItems = [heading]
                return section
            case .board:
                let section = full(Lobby.boardSide)
                section.boundarySupplementaryItems = [heading]
                return section
            case .footer:
                return full(120)
            }
        }
    }

    // MARK: Rendering

    private func renderLog() {
        logLabel.text = log.text
        countLabel.text = log.countText
    }

    private func renderDelay() {
        for (seconds, button) in delayButtons {
            let on = seconds == model.lobbySavedDelay
            button.backgroundColor = on ? Palette.secondaryContainer : .clear
            button.setTitleColor(on ? Palette.onSecondaryContainer : Palette.onSurface, for: .normal)
            button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline).withWeight(on ? .bold : .regular)
            button.accessibilityTraits = on ? [.button, .selected] : .button
        }
        delayRow.layer.borderColor = Palette.outline.resolvedColor(with: traitCollection).cgColor
    }

    /// Off, the pager's frame leaves its superview: no view, no node in the tree. On, it comes back on its banner.
    private func renderPagerShown() {
        pagerSwitch.toggle.isOn = model.lobbyPagerShown
        if model.lobbyPagerShown {
            if pagerFrame.superview == nil {
                lobbyStack.insertArrangedSubview(pagerFrame, at: 0)
                lobbyStack.layoutIfNeeded()
                if banner > 1 && pager.bounds.width > 0 {
                    pager.scrollToItem(at: IndexPath(item: banner - 1, section: 0), at: .left, animated: false)
                }
            }
        } else {
            setAuto(false)
            pagerFrame.removeFromSuperview()
        }
        renderPagerPosition()
        renderTopPosition()
    }

    private func renderPagerPosition() {
        let position = Lobby.pagerPosition(banner)
        pagerPositionLabel.text = position
        pagerPosition.accessibilityLabel = position
        for (i, dot) in dots.enumerated() {
            let on = i + 1 == banner
            dot.backgroundColor = on ? Palette.primary : Palette.outlineVariant
            dot.transform = on ? .identity : CGAffineTransform(scaleX: 0.6, y: 0.6)
        }
    }

    private func renderTopPosition() {
        let width = topRow.bounds.width > 0 ? topRow.bounds.width : view.bounds.width
        let range = Lobby.fullyVisible(offset: topRow.contentOffset.x, viewport: width, count: Lobby.topTiles)
        let position = Lobby.topRowPosition(first: range.first, last: range.last)
        topPositionLabel.text = position
        topPositionLabel.accessibilityLabel = position
    }

    private func renderBar() {
        let shown = SavedClock(delay: model.lobbySavedDelay, started: clockStart).shown(at: .now)
        let saved = barButtons["Saved"]!
        // Saved leaves the bar, not just the screen: until its delay has passed it is in no tree
        if shown && saved.superview == nil {
            bar.insertArrangedSubview(saved, at: 2)
        } else if !shown && saved.superview != nil {
            bar.removeArrangedSubview(saved)
            saved.removeFromSuperview()
        }
        for (label, button) in barButtons {
            let on = label == barSelected
            button.tintColor = on ? Palette.primary : Palette.onSurfaceVariant
            button.accessibilityTraits = on ? [.button, .selected] : .button
        }
    }

    private func renderPanel() {
        panelHost.subviews.forEach { $0.removeFromSuperview() }
        // the Lobby stays where it is under a panel, hidden, so every scroller keeps its place
        lobbyStack.isHidden = panel != nil
        panelHost.isHidden = panel == nil
        guard let panel else { return }
        let column = UIStackView()
        column.axis = .vertical
        column.alignment = .center
        column.spacing = 8
        column.translatesAutoresizingMaskIntoConstraints = false
        func text(_ string: String, _ style: UIFont.TextStyle, _ weight: UIFont.Weight = .regular) {
            let label = lobbyLabel(style, weight: weight)
            label.text = string
            label.numberOfLines = 0
            label.textAlignment = .center
            column.addArrangedSubview(label)
        }
        func back(_ id: String) {
            var configuration = UIButton.Configuration.bordered()
            configuration.title = Lobby.backToLobby
            configuration.cornerStyle = .capsule
            let button = UIButton(configuration: configuration)
            button.tintColor = Palette.primary
            button.accessibilityIdentifier = id
            button.addAction(UIAction { [weak self] _ in self?.panel = nil }, for: .touchUpInside)
            column.setCustomSpacing(16, after: column.arrangedSubviews.last!)
            column.addArrangedSubview(button)
        }
        switch panel {
        case .detail(let row, let tile):
            let item = Lobby.item(row: row, tile: tile)
            let drawing = GlyphView(glyph: 60)
            drawing.show(item)
            drawing.isAccessibilityElement = true
            drawing.accessibilityLabel = Texts.drawingOf(item.name)
            NSLayoutConstraint.activate([drawing.widthAnchor.constraint(equalToConstant: 96), drawing.heightAnchor.constraint(equalToConstant: 96)])
            column.addArrangedSubview(drawing)
            text(item.name, .title2, .semibold)
            let number = UILabel()
            number.text = item.number
            number.font = .monospacedSystemFont(ofSize: 13, weight: .medium)
            number.textColor = Palette.tertiary
            column.addArrangedSubview(number)
            text(Lobby.detailPlace(row: row, tile: tile), .body)
            back(TestIds.lobbyDetailBack)
            column.accessibilityIdentifier = TestIds.lobbyDetail
        case .promo(let n):
            text(Lobby.bannerTitles[n - 1], .title2, .semibold)
            text(Lobby.pagerPosition(n), .subheadline, .medium)
            text(Lobby.promoNote, .body)
            back(TestIds.lobbyPromoBack)
            column.accessibilityIdentifier = TestIds.lobbyPromo
        case .saved:
            let icon = UIImageView(image: Art.uiIcon("check"))
            icon.tintColor = Palette.onSurfaceVariant
            NSLayoutConstraint.activate([icon.widthAnchor.constraint(equalToConstant: 40), icon.heightAnchor.constraint(equalToConstant: 40)])
            column.addArrangedSubview(icon)
            text(Lobby.savedEmpty, .title3, .semibold)
            column.accessibilityIdentifier = TestIds.lobbySavedScreen
        }
        panelHost.addSubview(column)
        NSLayoutConstraint.activate([
            column.centerYAnchor.constraint(equalTo: panelHost.centerYAnchor),
            column.leadingAnchor.constraint(equalTo: panelHost.leadingAnchor, constant: 24),
            column.trailingAnchor.constraint(equalTo: panelHost.trailingAnchor, constant: -24),
        ])
    }

    // MARK: Actions

    /// When the count toward Saved started: the Lobby's opening, then each choice of a delay.
    private var clockStart = Date.now

    private func choose(_ seconds: Int) {
        model.lobbySavedDelay = seconds
        clockStart = .now
        renderDelay()
        restartClock()
    }

    private func restartClock() {
        savedTask?.cancel()
        renderBar()
        let clock = SavedClock(delay: model.lobbySavedDelay, started: clockStart)
        let wait = clock.remaining(at: .now)
        guard wait > 0 else { return }
        savedTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(wait))
            guard !Task.isCancelled else { return }
            self?.renderBar()
        }
    }

    private func barTapped(_ label: String) {
        log.add(.tap, label, "bar")
        barSelected = label
        panel = label == "Saved" ? .saved : nil
        renderBar()
    }

    private func setAuto(_ on: Bool) {
        autoSwitch.toggle.isOn = on
        autoTask?.cancel()
        guard on else { return }
        autoTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Lobby.autoAdvanceSeconds))
                guard !Task.isCancelled, let self else { return }
                let next = banner % Lobby.banners + 1
                pager.scrollToItem(at: IndexPath(item: next - 1, section: 0), at: .left, animated: true)
            }
        }
    }

    private func openSheet(_ target: LobbySheetTarget) {
        let sheet = QuickSheetController(title: target.title) { [weak self] label in
            guard let self else { return }
            log.add(.tap, label, "quick sheet, \(target.title)")
            dismiss(animated: true)
            if label == "Open" { panel = target.opens }
        }
        if let controller = sheet.sheetPresentationController {
            controller.detents = [.medium()]
            controller.prefersGrabberVisible = true
        }
        present(sheet, animated: true)
    }

    /// The top bar's Back: closes the detail or the promo, and leaves the Lobby otherwise.
    func backClosesPanel() -> Bool {
        guard let panel, panel.closesWithBack else { return false }
        self.panel = nil
        return true
    }

    // MARK: Positions

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        nameOrthogonalScrollers()
    }

    /// The chip and tile sections scroll in a scroll view UIKit makes for each of them, between their cells and the
    /// page. It gets the section's id (`lobby_chips`, `lobby_row_3`) once one of its cells is shown, and a tile row's
    /// position follows its offset from then on.
    private func nameOrthogonalScrollers() {
        for path in page.indexPathsForVisibleItems where path.section <= Section.row4.rawValue {
            guard let cell = page.cellForItem(at: path) else { continue }
            var view = cell.superview
            while let current = view, current !== page {
                if let scroller = current as? UIScrollView {
                    let row = path.section - Section.row1.rawValue + 1
                    scroller.accessibilityIdentifier = path.section == Section.chips.rawValue ? TestIds.lobbyChips : TestIds.lobbyRow(row)
                    if path.section != Section.chips.rawValue && rowScrollers[row] == nil {
                        rowScrollers[row] = scroller.observe(\.contentOffset, options: [.new]) { [weak self] _, _ in
                            MainActor.assumeIsolated { self?.renderRowPosition(row) }
                        }
                    }
                    break
                }
                view = current.superview
            }
        }
    }

    /// A tile row's position from where its tiles are on screen: the first and last whose whole frame is inside the page.
    private func renderRowPosition(_ row: Int) {
        let section = Section.row1.rawValue + row - 1
        let shown = page.indexPathsForVisibleItems.filter { $0.section == section }.compactMap { path -> Int? in
            guard let cell = page.cellForItem(at: path) else { return nil }
            let frame = cell.convert(cell.bounds, to: page)
            return frame.minX >= page.bounds.minX - 0.5 && frame.maxX <= page.bounds.maxX + 0.5 ? path.item + 1 : nil
        }.sorted()
        let range = shown.isEmpty ? (rowRanges[row] ?? (1, 3)) : (shown.first!, shown.last!)
        rowRanges[row] = range
        if let heading = page.supplementaryView(forElementKind: HeadingView.kind, at: IndexPath(item: 0, section: section)) as? HeadingView {
            showRowPosition(row, on: heading)
        }
    }

    private func showRowPosition(_ row: Int, on heading: HeadingView) {
        let range = rowRanges[row] ?? (1, 3)
        let position = Lobby.rowPosition(row: row, first: range.first, last: range.last)
        heading.label.text = position
        heading.label.accessibilityLabel = position
        heading.label.accessibilityIdentifier = TestIds.lobbyRowPosition(row)
    }

    private func showBoardPosition(on heading: HeadingView) {
        let position = Lobby.boardPosition(col: boardCorner.col, row: boardCorner.row)
        heading.label.text = position
        heading.label.accessibilityLabel = position
        heading.label.accessibilityIdentifier = TestIds.lobbyBoardPosition
    }

    private func touchedTile(row: Int, tile: Int, _ touch: Touch) {
        let item = Lobby.item(row: row, tile: tile)
        log.add(touch, item.name, Lobby.tileWhere(row: row, tile: tile))
        switch touch {
        case .tap: panel = .detail(row: row, tile: tile)
        case .longPress: openSheet(LobbySheetTarget(title: item.name, opens: .detail(row: row, tile: tile)))
        case .doubleTap: break
        }
    }
}

// MARK: Data

extension LobbyViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        collectionView === page ? Section.allCases.count : 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection index: Int) -> Int {
        if collectionView === pager { return Lobby.banners }
        if collectionView === topRow { return Lobby.topTiles }
        switch Section(rawValue: index)! {
        case .chips: return Lobby.chips.count
        case .row1, .row2, .row3, .row4: return Lobby.tiles
        case .grid, .inner, .board, .footer: return 1
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt path: IndexPath) -> UICollectionViewCell {
        let n = path.item + 1
        if collectionView === pager {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BannerCell.reuse, for: path) as! BannerCell
            let title = Lobby.bannerTitles[path.item]
            cell.show(title)
            cell.name(TestIds.lobbyBanner(n), label: title)
            cell.touched = { [weak self] touch in
                guard let self else { return }
                log.add(touch, title, "banner \(n)")
                if touch == .tap { panel = .promo(n) }
                if touch == .longPress { openSheet(LobbySheetTarget(title: title, opens: .promo(n))) }
            }
            return cell
        }
        if collectionView === topRow {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TopTileCell.reuse, for: path) as! TopTileCell
            let item = Lobby.topItem(n)
            cell.show(item)
            cell.name(TestIds.lobbyTopRowTile(n), label: item.name)
            cell.touched = { [weak self] touch in self?.touchedTile(row: Lobby.topRow, tile: n, touch) }
            return cell
        }
        let section = Section(rawValue: path.section)!
        switch section {
        case .chips:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChipCell.reuse, for: path) as! ChipCell
            let label = Lobby.chips[path.item]
            cell.show(label, selected: n == chip)
            cell.name(TestIds.lobbyChip(n), label: label)
            cell.touched = { [weak self] touch in
                guard let self else { return }
                log.add(touch, label, "chip \(n)")
                if touch == .tap {
                    chip = n
                    page.reconfigureItems(at: page.indexPathsForVisibleItems.filter { $0.section == Section.chips.rawValue })
                }
            }
            return cell
        case .row1, .row2, .row3, .row4:
            let row = path.section - Section.row1.rawValue + 1
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TileCell.reuse, for: path) as! TileCell
            let item = Lobby.tileItem(row: row, tile: n)
            cell.show(item)
            cell.name(TestIds.lobbyRowTile(row, n), label: item.name)
            cell.touched = { [weak self] touch in self?.touchedTile(row: row, tile: n, touch) }
            return cell
        case .grid, .inner, .board, .footer:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HostCell.reuse, for: path) as! HostCell
            switch section {
            case .grid: cell.hold(grid)
            case .inner: cell.hold(innerList)
            case .board: cell.hold(board, centred: Lobby.boardSide)
            default: cell.hold(footer)
            }
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at path: IndexPath) -> UICollectionReusableView {
        let heading = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HeadingView.reuse, for: path) as! HeadingView
        heading.label.accessibilityIdentifier = nil
        heading.label.accessibilityLabel = nil
        switch Section(rawValue: path.section)! {
        case .row1, .row2, .row3, .row4: showRowPosition(path.section - Section.row1.rawValue + 1, on: heading)
        case .grid: heading.label.text = Lobby.grid
        case .inner: heading.label.text = Lobby.innerList
        case .board: showBoardPosition(on: heading)
        default: heading.label.text = nil
        }
        return heading
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt path: IndexPath) {
        guard collectionView === page, path.section <= Section.row4.rawValue else { return }
        // the cell may not be in its scroller yet: look once this layout pass is over
        DispatchQueue.main.async { [weak self] in self?.nameOrthogonalScrollers() }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView === pager, pager.bounds.width > 0 {
            let now = Lobby.banner(offset: pager.contentOffset.x, pageWidth: pager.bounds.width)
            if now != banner {
                banner = now
                renderPagerPosition()
            }
        } else if scrollView === topRow {
            renderTopPosition()
        } else if scrollView === board {
            let corner = Lobby.boardTopLeft(x: board.contentOffset.x, y: board.contentOffset.y)
            guard corner != boardCorner else { return }
            boardCorner = corner
            if let heading = page.supplementaryView(forElementKind: HeadingView.kind, at: IndexPath(item: 0, section: Section.board.rawValue)) as? HeadingView {
                showBoardPosition(on: heading)
            }
        }
    }
}

extension LobbyViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { Lobby.innerLines }

    func tableView(_ tableView: UITableView, cellForRowAt path: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: InnerLineCell.reuse, for: path) as! InnerLineCell
        let n = path.row + 1
        cell.textLabel?.text = Lobby.innerLine(n)
        cell.accessibilityLabel = Lobby.innerLine(n)
        cell.accessibilityIdentifier = TestIds.lobbyInnerRow(n)
        cell.touched = { [weak self] touch in self?.log.add(touch, "Line \(n)", "inner list") }
        return cell
    }
}

/// The quick sheet: a view controller in UIKit's own sheet, at the medium detent. A drag down or a tap outside closes
/// it, with no log line.
private final class QuickSheetController: UIViewController {
    private let sheetTitle: String
    private let tapped: (String) -> Void

    init(title: String, tapped: @escaping (String) -> Void) {
        sheetTitle = title
        self.tapped = tapped
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("not from a storyboard") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.surfaceContainerLow
        view.accessibilityIdentifier = TestIds.lobbySheet
        let title = lobbyLabel(.title3, weight: .semibold)
        title.text = sheetTitle
        title.accessibilityTraits = .header
        title.accessibilityIdentifier = TestIds.lobbySheetTitle
        let stack = UIStackView(arrangedSubviews: [title])
        stack.axis = .vertical
        stack.spacing = 4
        stack.setCustomSpacing(12, after: title)
        for (label, id) in [("Open", TestIds.lobbySheetOpen), ("Preview", TestIds.lobbySheetPreview), ("Saved", TestIds.lobbySheetSaved),
                            ("Rate", TestIds.lobbySheetRate)] {
            var configuration = UIButton.Configuration.plain()
            configuration.title = label
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)
            let button = UIButton(configuration: configuration)
            button.contentHorizontalAlignment = .leading
            button.tintColor = Palette.primary
            button.accessibilityIdentifier = id
            button.addAction(UIAction { [weak self] _ in self?.tapped(label) }, for: .touchUpInside)
            stack.addArrangedSubview(button)
        }
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
    }
}

private extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: pointSize, weight: weight))
    }
}

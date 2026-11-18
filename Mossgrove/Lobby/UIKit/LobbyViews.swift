import MossgroveKit
import UIKit

// The UIKit Lobby's views. Every touchable one takes UIKit's own recognizers: a double tap, a tap that waits for the
// double tap to fail (`require(toFail:)`), and a long press with its defaults (0.5 s, 10 points of movement). Nothing
// here adds a rule of its own for a finger that moves.

/// The three recognizers of a touchable view, installed once; `touched` says which one fired.
final class TouchRecognizers: NSObject {
    var touched: ((Touch, CGPoint) -> Void)?

    init(on view: UIView) {
        super.init()
        let double = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
        double.numberOfTapsRequired = 2
        let single = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        single.require(toFail: double)
        let long = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        for recognizer in [double, single, long] { view.addGestureRecognizer(recognizer) }
        view.isUserInteractionEnabled = true
    }

    @objc private func tap(_ recognizer: UITapGestureRecognizer) {
        touched?(.tap, recognizer.location(in: recognizer.view))
    }

    @objc private func doubleTap(_ recognizer: UITapGestureRecognizer) {
        touched?(.doubleTap, recognizer.location(in: recognizer.view))
    }

    @objc private func longPress(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began else { return }
        touched?(.longPress, recognizer.location(in: recognizer.view))
    }
}

/// A collection view cell that is one touchable accessibility element: its id, its label, the button trait.
class TouchCell: UICollectionViewCell {
    private lazy var recognizers = TouchRecognizers(on: contentView)
    var touched: ((Touch) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = true
        accessibilityTraits = .button
        recognizers.touched = { [weak self] touch, _ in self?.touched?(touch) }
    }

    required init?(coder: NSCoder) { fatalError("not from a storyboard") }

    func name(_ id: String, label: String) {
        accessibilityIdentifier = id
        accessibilityLabel = label
    }
}

func lobbyLabel(_ style: UIFont.TextStyle, weight: UIFont.Weight = .regular, color: UIColor = Palette.onSurface) -> UILabel {
    let label = UILabel()
    let base = UIFont.preferredFont(forTextStyle: style)
    label.font = UIFontMetrics(forTextStyle: style).scaledFont(for: .systemFont(ofSize: base.pointSize, weight: weight))
    label.adjustsFontForContentSizeCategory = true
    label.textColor = color
    return label
}

/// An item's drawing on its aisle's tint, `width` × `height`, the drawing `glyph` points square.
final class GlyphView: UIView {
    private let image = UIImageView()

    init(glyph: CGFloat) {
        super.init(frame: .zero)
        layer.cornerRadius = 8
        layer.cornerCurve = .continuous
        image.contentMode = .scaleAspectFit
        image.translatesAutoresizingMaskIntoConstraints = false
        addSubview(image)
        NSLayoutConstraint.activate([
            image.centerXAnchor.constraint(equalTo: centerXAnchor), image.centerYAnchor.constraint(equalTo: centerYAnchor),
            image.widthAnchor.constraint(equalToConstant: glyph), image.heightAnchor.constraint(equalToConstant: glyph),
        ])
        isAccessibilityElement = false
    }

    required init?(coder: NSCoder) { fatalError("not from a storyboard") }

    func show(_ item: Item) {
        backgroundColor = Palette.tile(item.aisle)
        image.image = UIImage(named: "glyph-\(item.glyph.rawValue)")?.withRenderingMode(.alwaysTemplate)
        image.tintColor = Palette.ink(item.aisle)
    }
}

/// A tile of the page's rows: the drawing 100 square, the name, the number in brass.
final class TileCell: TouchCell {
    static let reuse = "tile"
    private let glyph = GlyphView(glyph: 62)
    private let nameLabel = lobbyLabel(.caption1)
    private let numberLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        numberLabel.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: .monospacedSystemFont(ofSize: 13, weight: .medium))
        numberLabel.adjustsFontForContentSizeCategory = true
        numberLabel.textColor = Palette.tertiary
        let stack = UIStackView(arrangedSubviews: [glyph, nameLabel, numberLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            glyph.widthAnchor.constraint(equalToConstant: Lobby.tileWidth),
            glyph.heightAnchor.constraint(equalToConstant: Lobby.tileWidth),
        ])
    }

    required init?(coder: NSCoder) { fatalError("not from a storyboard") }

    func show(_ item: Item) {
        glyph.show(item)
        nameLabel.text = item.name
        numberLabel.text = item.number
    }
}

/// A Top 10 tile: the drawing in a band 100 × 64, and the name under it.
final class TopTileCell: TouchCell {
    static let reuse = "top"
    private let glyph = GlyphView(glyph: 40)
    private let nameLabel = lobbyLabel(.caption1)

    override init(frame: CGRect) {
        super.init(frame: frame)
        let stack = UIStackView(arrangedSubviews: [glyph, nameLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            glyph.widthAnchor.constraint(equalToConstant: Lobby.tileWidth),
            glyph.heightAnchor.constraint(equalToConstant: Lobby.topBandHeight),
        ])
    }

    required init?(coder: NSCoder) { fatalError("not from a storyboard") }

    func show(_ item: Item) {
        glyph.show(item)
        nameLabel.text = item.name
    }
}

/// A banner of the pager: its title and "A test banner" on the enamel container, inset 16 points from the page.
final class BannerCell: TouchCell {
    static let reuse = "banner"
    private let card = UIView()
    private let titleLabel = lobbyLabel(.headline, color: Palette.onPrimaryContainer)
    private let noteLabel = lobbyLabel(.footnote, color: Palette.onPrimaryContainer)

    override init(frame: CGRect) {
        super.init(frame: frame)
        card.backgroundColor = Palette.primaryContainer
        card.layer.cornerRadius = 12
        card.layer.cornerCurve = .continuous
        card.translatesAutoresizingMaskIntoConstraints = false
        noteLabel.text = Lobby.testBanner
        let stack = UIStackView(arrangedSubviews: [titleLabel, noteLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("not from a storyboard") }

    func show(_ title: String) { titleLabel.text = title }
}

/// A chip: its label, and a check mark while it is selected.
final class ChipCell: TouchCell {
    static let reuse = "chip"
    private let check = UIImageView(image: Art.uiIcon("check"))
    private let titleLabel = lobbyLabel(.subheadline, weight: .medium)

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 8
        contentView.layer.borderWidth = 1
        check.translatesAutoresizingMaskIntoConstraints = false
        let stack = UIStackView(arrangedSubviews: [check, titleLabel])
        stack.spacing = 6
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            check.widthAnchor.constraint(equalToConstant: 16), check.heightAnchor.constraint(equalToConstant: 16),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
        ])
    }

    required init?(coder: NSCoder) { fatalError("not from a storyboard") }

    func show(_ label: String, selected: Bool) {
        titleLabel.text = label
        check.isHidden = !selected
        check.tintColor = Palette.onSecondaryContainer
        titleLabel.textColor = selected ? Palette.onSecondaryContainer : Palette.onSurface
        contentView.backgroundColor = selected ? Palette.secondaryContainer : Palette.surface
        contentView.layer.borderColor = (selected ? Palette.secondaryContainer : Palette.outline).resolvedColor(with: traitCollection).cgColor
        accessibilityTraits = selected ? [.button, .selected] : .button
    }
}

/// A grid cell: the drawing 40 square and the name, in a thin frame. It is one touchable accessibility element.
final class GridCellView: UIView {
    private let glyph = GlyphView(glyph: 25)
    private let nameLabel = lobbyLabel(.footnote)
    private lazy var recognizers = TouchRecognizers(on: self)
    var touched: ((Touch) -> Void)?

    init(item: Item) {
        super.init(frame: .zero)
        layer.cornerRadius = 8
        layer.borderWidth = 1
        nameLabel.numberOfLines = 2
        nameLabel.text = item.name
        glyph.show(item)
        let stack = UIStackView(arrangedSubviews: [glyph, nameLabel])
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            glyph.widthAnchor.constraint(equalToConstant: 40), glyph.heightAnchor.constraint(equalToConstant: 40),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(equalToConstant: 56),
        ])
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = item.name
        recognizers.touched = { [weak self] touch, _ in self?.touched?(touch) }
        recolour()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (cell: GridCellView, _: UITraitCollection) in cell.recolour() }
    }

    required init?(coder: NSCoder) { fatalError("not from a storyboard") }

    private func recolour() { layer.borderColor = Palette.outlineVariant.resolvedColor(with: traitCollection).cgColor }
}

/// A cell that holds one view the controller keeps (the inner list, the board, the footer), so the view and its
/// scroll position outlive the cell's reuse.
final class HostCell: UICollectionViewCell {
    static let reuse = "host"

    func hold(_ view: UIView, centred width: CGFloat? = nil) {
        guard view.superview !== contentView else { return }
        contentView.subviews.forEach { $0.removeFromSuperview() }
        view.removeFromSuperview()
        view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(view)
        var constraints = [view.topAnchor.constraint(equalTo: contentView.topAnchor),
                           view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)]
        if let width {
            constraints += [view.centerXAnchor.constraint(equalTo: contentView.centerXAnchor), view.widthAnchor.constraint(equalToConstant: width)]
        } else {
            constraints += [view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)]
        }
        NSLayoutConstraint.activate(constraints)
    }
}

/// A section's heading: "Grid", "Inner list", a row's position, the board's position.
final class HeadingView: UICollectionReusableView {
    static let kind = UICollectionView.elementKindSectionHeader
    static let reuse = "heading"
    let label = lobbyLabel(.subheadline, weight: .semibold, color: Palette.primary)

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityTraits = .header
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
        ])
    }

    required init?(coder: NSCoder) { fatalError("not from a storyboard") }
}

/// A line of the inner list.
final class InnerLineCell: UITableViewCell {
    static let reuse = "line"
    private lazy var recognizers = TouchRecognizers(on: contentView)
    var touched: ((Touch) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        isAccessibilityElement = true
        accessibilityTraits = .button
        textLabel?.font = .preferredFont(forTextStyle: .body)
        textLabel?.textColor = Palette.onSurface
        recognizers.touched = { [weak self] touch, _ in self?.touched?(touch) }
    }

    required init?(coder: NSCoder) { fatalError("not from a storyboard") }
}

/// The board: a `UIScrollView` whose content, 26 × 26 cells of 56 points, is wider and taller than its 280-point frame,
/// so it scrolls both ways. Each cell is a label that is its own accessibility element with its id; the touches are
/// read on the content, at the cell under the finger.
final class BoardView: UIScrollView {
    let content = UIView()
    private lazy var recognizers = TouchRecognizers(on: content)
    var touched: ((Touch, String) -> Void)?

    init(cellId: (Int, Int) -> String) {
        super.init(frame: .zero)
        let side = Lobby.boardCell * Double(Lobby.board)
        content.frame = CGRect(x: 0, y: 0, width: side, height: side)
        addSubview(content)
        contentSize = content.frame.size
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        layer.borderWidth = 1
        layer.cornerRadius = 4
        for row in 1...Lobby.board {
            for col in 1...Lobby.board {
                let cell = UILabel(frame: CGRect(x: Double(col - 1) * Lobby.boardCell, y: Double(row - 1) * Lobby.boardCell,
                                                 width: Lobby.boardCell, height: Lobby.boardCell))
                cell.text = Lobby.boardLabel(col: col, row: row)
                cell.textAlignment = .center
                cell.font = .preferredFont(forTextStyle: .caption1)
                cell.textColor = Palette.onSurface
                cell.layer.borderWidth = 0.5
                cell.isAccessibilityElement = true
                cell.accessibilityTraits = .button
                cell.accessibilityIdentifier = cellId(col, row)
                content.addSubview(cell)
            }
        }
        recognizers.touched = { [weak self] touch, point in
            let col = min(max(Int(point.x / Lobby.boardCell) + 1, 1), Lobby.board)
            let row = min(max(Int(point.y / Lobby.boardCell) + 1, 1), Lobby.board)
            self?.touched?(touch, Lobby.boardLabel(col: col, row: row))
        }
        recolour()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (board: BoardView, _: UITraitCollection) in board.recolour() }
    }

    required init?(coder: NSCoder) { fatalError("not from a storyboard") }

    private func recolour() {
        layer.borderColor = Palette.outline.resolvedColor(with: traitCollection).cgColor
        let line = Palette.outlineVariant.resolvedColor(with: traitCollection).cgColor
        content.subviews.forEach { $0.layer.borderColor = line }
    }
}

/// A switch and its title on one line; the switch is UIKit's own and carries the id.
final class SwitchRow: UIStackView {
    let toggle = UISwitch()

    init(title: String, id: String) {
        super.init(frame: .zero)
        let label = lobbyLabel(.subheadline, weight: .medium)
        label.text = title
        label.isAccessibilityElement = false
        toggle.accessibilityIdentifier = id
        toggle.accessibilityLabel = title
        toggle.onTintColor = Palette.primary
        addArrangedSubview(label)
        addArrangedSubview(toggle)
        spacing = 8
        alignment = .center
    }

    required init(coder: NSCoder) { fatalError("not from a storyboard") }
}

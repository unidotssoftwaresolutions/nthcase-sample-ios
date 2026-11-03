import MossgroveKit
import SwiftUI

extension View {
    /// An element that holds others and keeps their ids: a screen root, a card, a line. Without `.contain`, SwiftUI
    /// would hand the identifier down to every child that has none of its own.
    func container(_ id: String) -> some View {
        accessibilityElement(children: .contain).accessibilityIdentifier(id)
    }

    /// The page behind every screen: card stock.
    func screenBackground() -> some View {
        background(Color(Palette.surface).ignoresSafeArea())
    }
}

/// The outlined box of a text field: at least 48 points high, with a 1-point frame that turns error-red. The whole
/// box is one target: a tap anywhere in it, beside or above the line of text too, puts the cursor in the field
/// (`focus` sets the screen's @FocusState). The field keeps its own tap; the box's target sits behind it, so no
/// gesture is laid over the field, and the frame is drawing only. A box around a button (the dropdown, the date)
/// has no `focus`: the button is the target.
struct FieldBox<Content: View>: View {
    var isError = false
    var trailing: CGFloat = 12
    let focus: (() -> Void)?
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.leading, 12)
            .padding(.trailing, trailing)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            .background {
                if let focus {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture(perform: focus)
                        .accessibilityHidden(true)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isError ? Color(Palette.error) : Color(Palette.outline), lineWidth: 1)
                    .allowsHitTesting(false)
            }
    }
}

/// "No. 007" in brass monospace: the item's mark on every screen.
struct ItemNumber: View {
    let item: Item

    var body: some View {
        Text(item.number).font(Typeface.itemNumber).foregroundStyle(Color(Palette.tertiary))
    }
}

/// The item's drawing on its aisle's tint. The drawing fills 62 % of the tile.
struct GlyphTile: View {
    let item: Item
    let size: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color(Palette.tile(item.aisle)))
            .frame(width: size, height: size)
            .overlay {
                Art.glyph(item.glyph)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color(Palette.ink(item.aisle)))
                    .frame(width: size * 0.62, height: size * 0.62)
            }
    }
}

/// The label holder of a drawer front: a thin frame around the name and the number. It hugs its content.
struct LabelHolder: View {
    let item: Item
    var nameFont: Font = .headline

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.name).font(nameFont).foregroundStyle(Color(Palette.onSurface))
            ItemNumber(item: item)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(Palette.outlineVariant), lineWidth: 1))
    }
}

/// A − value + stepper. Each button and the value carry their own ids, from the caller. At 1 or 9 a button turns
/// off and loses its ring, so the state is a shape as well as a colour.
struct QuantityStepper: View {
    let value: Int
    let subject: String
    let decreaseId: String
    let valueId: String
    let increaseId: String
    let onChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 4) {
            StepButton(icon: "minus", label: "Decrease \(subject)", enabled: value > Cart.minQuantity) { onChange(value - 1) }
                .accessibilityIdentifier(decreaseId)
            Text("\(value)")
                .font(.headline)
                .monospacedDigit()
                .frame(minWidth: 40)
                .accessibilityIdentifier(valueId)
            StepButton(icon: "plus", label: "Increase \(subject)", enabled: value < Cart.maxQuantity) { onChange(value + 1) }
                .accessibilityIdentifier(increaseId)
        }
    }

    private struct StepButton: View {
        let icon: String
        let label: String
        let enabled: Bool
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Art.icon(icon)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .frame(width: 48, height: 48)
                    .overlay(Circle().stroke(enabled ? Color(Palette.outline) : .clear, lineWidth: 1))
                    .contentShape(Circle())
            }
            .foregroundStyle(enabled ? Color(Palette.onSurfaceVariant) : Color(Palette.onSurfaceVariant).opacity(0.38))
            .disabled(!enabled)
            .accessibilityLabel(label)
        }
    }
}

/// A full-width filled button: enamel green, or brass for Add to cart.
struct FilledButtonStyle: ButtonStyle {
    var fill = Color(Palette.primary)
    var text = Color(Palette.onPrimary)
    var fullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(text)
            .padding(.horizontal, 24)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: 48)
            .background(fill.opacity(configuration.isPressed ? 0.85 : 1), in: Capsule())
            .contentShape(Capsule())
    }
}

/// An outlined button: empty-state actions, Choose, Reload.
struct OutlinedButtonStyle: ButtonStyle {
    var color = Color(Palette.primary)
    var fullWidth = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 20)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: 44)
            .overlay(Capsule().stroke(Color(Palette.outline), lineWidth: 1))
            .background(Color.primary.opacity(configuration.isPressed ? 0.06 : 0), in: Capsule())
            .contentShape(Capsule())
    }
}

/// A centred message with an icon, a title, a line of help and one action: the shape of every empty and error state.
/// The message is one element carrying the state's id (it reads the title and the help); the action keeps its own.
struct StateMessage: View {
    let icon: String
    let title: String
    let message: String
    let id: String?
    var actionLabel: String?
    var actionId: String?
    var isError = false
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Art.icon(icon)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(isError ? Color(Palette.error) : Color(Palette.onSurfaceVariant))
                    .accessibilityHidden(true)
                Text(title).font(.title3).multilineTextAlignment(.center).foregroundStyle(Color(Palette.onSurface))
                Text(message).font(.subheadline).multilineTextAlignment(.center).foregroundStyle(Color(Palette.onSurfaceVariant))
            }
            .accessibilityElement(children: .combine)
            .testId(id)
            if let actionLabel, let action {
                if isError {
                    Button(actionLabel, action: action).buttonStyle(FilledButtonStyle(fullWidth: false)).testId(actionId)
                } else {
                    Button(actionLabel, action: action).buttonStyle(OutlinedButtonStyle()).testId(actionId)
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// A spinner with a line under it, for the slow loads. One element with the load's id.
struct LoadingView: View {
    let text: String
    let id: String

    var body: some View {
        VStack(spacing: 16) {
            ProgressView().controlSize(.large)
            Text(text).font(.subheadline).foregroundStyle(Color(Palette.onSurfaceVariant))
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(id)
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// The local stand-in for a network load (there is no network). Each screen starts it when it opens; the rules are
/// LoadPlan's: 3 s when slow, the first attempt fails when Fail the first load is on, Try again succeeds.
@MainActor
@Observable
final class LoadModel {
    private(set) var status: LoadStatus = .ready
    private var attempt = 0
    private var task: Task<Void, Never>?

    func start(slow: Bool, fail: Bool) {
        attempt = 0
        run(slow: slow, fail: fail)
    }

    func retry(slow: Bool, fail: Bool) {
        attempt += 1
        run(slow: slow, fail: fail)
    }

    func stop() { task?.cancel() }

    private func run(slow: Bool, fail: Bool) {
        task?.cancel()
        status = LoadPlan.first(slow: slow, fail: fail, attempt: attempt)
        guard status == .loading else { return }
        let attempt = attempt
        task = Task { [weak self] in
            try? await Task.sleep(for: .seconds(LoadPlan.slowSeconds))
            guard !Task.isCancelled else { return }
            self?.status = LoadPlan.afterWait(fail: fail, attempt: attempt)
        }
    }
}

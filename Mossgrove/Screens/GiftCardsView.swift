import MossgroveKit
import SwiftUI

/// The screen with no test ids at all (SPEC.md §5, Gift cards). Nothing here carries an identifier, its top bar
/// included, so NthCase must find each control by its visible text, its label and its position. Two buttons share
/// the text "Choose": only their position tells them apart.
struct GiftCardsView: View {
    @State private var code = ""
    @State private var result: String?
    @State private var amount = 25
    @State private var design: String?
    @FocusState private var codeFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(Texts.checkBalance).font(.headline)
                OutlinedField(label: Texts.cardCode, focus: { codeFocused = true }) {
                    TextField(Texts.cardCode, text: $code)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .focused($codeFocused)
                        .onChange(of: code) {
                            let upper = code.uppercased()
                            if upper != code { code = upper }
                            result = nil
                        }
                }
                Button(Texts.checkBalanceButton) { result = GiftCards.check(code) }
                    .buttonStyle(FilledButtonStyle())
                if let result {
                    Text(result).font(.headline)
                }

                Text(Texts.buyCard).font(.headline).padding(.top, 8)
                HStack(spacing: 8) {
                    ForEach(GiftCards.amounts, id: \.self) { value in
                        Button { amount = value } label: {
                            HStack(spacing: 6) {
                                // selected is a mark as well as a tint
                                if amount == value { Art.icon("check").resizable().frame(width: 18, height: 18).accessibilityHidden(true) }
                                Text("$\(value)")
                            }
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 12)
                            .frame(minHeight: 32)
                            .background(amount == value ? Color(Palette.secondaryContainer) : .clear, in: RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(amount == value ? .clear : Color(Palette.outline), lineWidth: 1))
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(amount == value ? Color(Palette.onSecondaryContainer) : Color(Palette.onSurfaceVariant))
                        .accessibilityAddTraits(amount == value ? .isSelected : [])
                    }
                }
                HStack(alignment: .top, spacing: 12) {
                    DesignCard(title: "Fern", detail: "Green leaves", aisle: .garden, chosen: design == "Fern") { design = "Fern" }
                    DesignCard(title: "Stone", detail: "Grey pebbles", aisle: .home, chosen: design == "Stone") { design = "Stone" }
                }
                Text(GiftCards.choice(amount: amount, design: design)).font(.body)
            }
            .foregroundStyle(Color(Palette.onSurface))
            .padding(16)
        }
        .screenBackground()
        .topBar("Gift cards", back: true, tagged: false)
    }
}

/// A gift-card design: a picture of it, its name, and Choose. The chosen one has a check and a 2-point primary border.
private struct DesignCard: View {
    let title: String
    let detail: String
    let aisle: Aisle
    let chosen: Bool
    let choose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(Palette.tile(aisle)))
                .frame(height: 72)
                .overlay {
                    if aisle == .garden {
                        Art.glyph(.plant).resizable().frame(width: 44, height: 44)
                    } else {
                        Pebbles().stroke(lineWidth: 2.5).frame(width: 64, height: 36)
                    }
                }
                .foregroundStyle(Color(Palette.ink(aisle)))
                .accessibilityHidden(true)
            HStack {
                Text(title).font(.subheadline.weight(.semibold))
                Spacer()
                if chosen {
                    Art.icon("check").resizable().frame(width: 18, height: 18).foregroundStyle(Color(Palette.primary)).accessibilityLabel("Chosen")
                }
            }
            Text(detail).font(.caption).foregroundStyle(Color(Palette.onSurfaceVariant))
            Button(Texts.choose, action: choose)
                .buttonStyle(OutlinedButtonStyle(fullWidth: true))
                .padding(.top, 4)
        }
        .padding(12)
        .background(Color(Palette.surfaceContainerLow), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(chosen ? Color(Palette.primary) : .clear, lineWidth: 2))
        .frame(maxWidth: .infinity)
    }
}

/// Three pebbles, drawn for this card.
private struct Pebbles: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.addEllipse(in: CGRect(x: rect.minX, y: rect.minY + h * 0.35, width: w * 0.42, height: h * 0.6))
        path.addEllipse(in: CGRect(x: rect.minX + w * 0.36, y: rect.minY, width: w * 0.34, height: h * 0.5))
        path.addEllipse(in: CGRect(x: rect.minX + w * 0.56, y: rect.minY + h * 0.45, width: w * 0.44, height: h * 0.52))
        return path
    }
}

import MossgroveKit
import SwiftUI

/// The detail page. `rawId` is the route's (or the deep link's) id as written, so an unknown id can say so.
struct ItemView: View {
    let rawId: String
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var quantity = 1

    var body: some View {
        ZStack {
            if let item = Catalog.find(raw: rawId) {
                detail(item)
            } else {
                StateMessage(icon: "empty", title: Texts.noSuchItem(rawId), message: Texts.itemsNumbered(Catalog.items.count),
                             id: TestIds.itemNotFound, actionLabel: Texts.backToShop, actionId: TestIds.itemNotFoundAction) {
                    dismiss()
                }
            }
        }
        .screenBackground()
        .screen(TestIds.itemScreen)
        .topBar(Catalog.find(raw: rawId)?.name ?? Texts.notFound, back: true)
    }

    private func detail(_ item: Item) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                GlyphTile(item: item, size: 220)
                    .frame(maxWidth: .infinity)
                    .accessibilityElement()
                    .accessibilityLabel(Texts.drawingOf(item.name))
                    .accessibilityAddTraits(.isImage)
                    .accessibilityIdentifier(TestIds.itemImage)
                // the drawer's label holder, at the scale of the page: the name, then its number
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name).font(.title2).accessibilityIdentifier(TestIds.itemName)
                    ItemNumber(item: item).accessibilityIdentifier(TestIds.itemNumber)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(Palette.outlineVariant), lineWidth: 1))
                .padding(.top, 4)
                Text(item.price).font(.title3).accessibilityIdentifier(TestIds.itemPrice)
                Text(item.description)
                    .font(.body)
                    .foregroundStyle(Color(Palette.onSurfaceVariant))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(TestIds.itemDescription)
                Text("\(item.aisle.label) aisle").font(.subheadline.weight(.medium)).foregroundStyle(Color(Palette.onSurfaceVariant))
                HStack {
                    Text("Quantity").font(.subheadline.weight(.semibold))
                    Spacer()
                    QuantityStepper(value: quantity, subject: item.name, decreaseId: TestIds.itemQtyDecrease,
                                    valueId: TestIds.itemQtyValue, increaseId: TestIds.itemQtyIncrease) { quantity = $0 }
                }
                .padding(.top, 8)
                // brass, like the item number and the cart count it fills: the one live action of the page
                Button(Texts.addToCart(item.priceCents * quantity)) {
                    model.add(item.id, quantity: quantity)
                    model.showSnack(Texts.addedToCart, actionLabel: Texts.viewCart) { model.navigation.select(.cart) }
                }
                .buttonStyle(FilledButtonStyle(fill: Color(Palette.tertiary), text: Color(Palette.onTertiary)))
                .accessibilityIdentifier(TestIds.itemAddToCart)
            }
            .foregroundStyle(Color(Palette.onSurface))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
    }
}

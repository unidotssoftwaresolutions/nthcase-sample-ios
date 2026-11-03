import MossgroveKit
import SwiftUI

/// The cart: a line per item with its stepper and remove button, the total and Check out pinned below, and the
/// checkout dialog (the app's modal).
struct CartView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            if model.cart.isEmpty {
                StateMessage(icon: "cart", title: Texts.cartEmpty, message: Texts.cartEmptyHelp, id: TestIds.cartEmpty,
                             actionLabel: Texts.browseShop, actionId: TestIds.cartEmptyAction) {
                    model.navigation.select(.shop)
                }
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(model.cart.lines, id: \.itemId) { line in
                            CartLineRow(line: line)
                        }
                    }
                    .padding(16)
                }
                .accessibilityIdentifier(TestIds.cartList)
                .safeAreaInset(edge: .bottom) { checkoutPanel }
            }
        }
        .screenBackground()
        .container(TestIds.cartScreen)
        .topBar(AppTab.cart.title)
    }

    private var checkoutPanel: some View {
        VStack(spacing: 12) {
            HStack {
                Text(Texts.total).font(.headline)
                Spacer()
                Text(formatPrice(model.cart.totalCents)).font(.title3).accessibilityIdentifier(TestIds.cartTotal)
            }
            Button(Texts.checkOut, action: confirm)
                .buttonStyle(FilledButtonStyle())
                .accessibilityIdentifier(TestIds.cartCheckout)
        }
        .padding(16)
        .background(Color(Palette.surfaceContainer).ignoresSafeArea(edges: .horizontal))
    }

    private func confirm() {
        model.showDialog(DialogRequest(title: Texts.placeThisOrder, text: checkoutText(model.cart), confirmLabel: Texts.placeOrder) {
            let order = model.placeOrder()
            model.showSnack(Texts.orderPlaced(order.number), actionLabel: Texts.viewOrders) { model.navigation.push(.orders) }
        })
    }
}

private struct CartLineRow: View {
    let line: CartLine
    @Environment(AppModel.self) private var model

    var body: some View {
        let item = line.item
        VStack(spacing: 4) {
            HStack(spacing: 12) {
                GlyphTile(item: item, size: 48).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name).font(.headline)
                    ItemNumber(item: item)
                }
                Spacer()
                Text(formatPrice(line.totalCents)).font(.headline).accessibilityIdentifier(TestIds.cartLineTotal(item.id))
            }
            HStack(spacing: 4) {
                Text(Texts.each(item.priceCents)).font(.subheadline).foregroundStyle(Color(Palette.onSurfaceVariant))
                Spacer()
                QuantityStepper(value: line.quantity, subject: item.name, decreaseId: TestIds.cartLineDecrease(item.id),
                                valueId: TestIds.cartLineQty(item.id), increaseId: TestIds.cartLineIncrease(item.id)) {
                    model.setQuantity(item.id, $0)
                }
                Button { model.remove(item.id) } label: { Art.icon("trash").frame(width: 44, height: 44) }
                    .foregroundStyle(Color(Palette.onSurfaceVariant))
                    .accessibilityLabel("Remove \(item.name)")
                    .accessibilityIdentifier(TestIds.cartLineRemove(item.id))
            }
            Divider().overlay(Color(Palette.outlineVariant)).padding(.top, 8)
        }
        .foregroundStyle(Color(Palette.onSurface))
        .container(TestIds.cartLine(item.id))
    }
}

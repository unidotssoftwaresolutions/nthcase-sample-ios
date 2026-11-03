import MossgroveKit
import SwiftUI

/// Order history: the empty state and, with Settings › Fail the first load, the error state with retry.
struct OrdersView: View {
    @Environment(AppModel.self) private var model
    @State private var load = LoadModel()

    var body: some View {
        ZStack {
            switch load.status {
            case .loading:
                LoadingView(text: Texts.ordersLoading, id: TestIds.ordersLoading)
            case .failed:
                StateMessage(icon: "warning", title: Texts.ordersFailed, message: Texts.ordersFailedHelp, id: TestIds.ordersError,
                             actionLabel: Texts.tryAgain, actionId: TestIds.ordersRetry, isError: true) {
                    load.retry(slow: model.slowLoading, fail: model.failFirstLoad)
                }
            case .ready where model.orders.isEmpty:
                StateMessage(icon: "empty", title: Texts.noOrders, message: Texts.noOrdersHelp, id: TestIds.ordersEmpty,
                             actionLabel: Texts.startShopping, actionId: TestIds.ordersEmptyAction) {
                    model.navigation.select(.shop)
                }
            case .ready:
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(model.orders, id: \.number) { order in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(Texts.order(order.number)).font(.body)
                                    Text(order.summary).font(.subheadline).foregroundStyle(Color(Palette.onSurfaceVariant))
                                }
                                Spacer()
                                Text(formatPrice(order.totalCents)).font(.headline)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .accessibilityElement(children: .combine)
                            .accessibilityIdentifier(TestIds.ordersRow(order.number))
                            Divider().overlay(Color(Palette.outlineVariant)).padding(.horizontal, 16)
                        }
                    }
                    .foregroundStyle(Color(Palette.onSurface))
                }
                .accessibilityIdentifier(TestIds.ordersList)
            }
        }
        .screenBackground()
        .container(TestIds.ordersScreen)
        .topBar("Orders", back: true)
        .onAppear { load.start(slow: model.slowLoading, fail: model.failFirstLoad) }
        .onDisappear { load.stop() }
    }
}

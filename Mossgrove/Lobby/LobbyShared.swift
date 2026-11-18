import MossgroveKit
import SwiftUI
import UIKit

/// What takes the place of the pager, the Top 10 row and the page (SPEC.md §5, Lobby › Panels). Both Lobbies use it.
enum LobbyPanel: Equatable {
    /// `row` 1–4, or `Lobby.topRow` for the Top 10 row.
    case detail(row: Int, tile: Int)
    case promo(Int)
    case saved

    /// Back (the top bar's) closes the detail and the promo; the Saved panel closes with Home.
    var closesWithBack: Bool { self != .saved }
}

/// What a quick sheet was opened for: its title, and what its Open opens.
struct LobbySheetTarget: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let opens: LobbyPanel
}

enum LobbyArt {
    /// The bar's icons, from `art/icons`.
    static func barIcon(_ label: String) -> String {
        switch label {
        case "Home": "shop"
        case "Live": "eye"
        case "Saved": "check"
        default: "cart"
        }
    }
}

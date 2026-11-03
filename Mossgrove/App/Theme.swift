import MossgroveKit
import SwiftUI
import UIKit

/// The Mossgrove palette (SPEC.md §10, DESIGN.md): cabinet-enamel green, cool card-stock neutrals, and one brass
/// accent kept for the item number, Add to cart and the cart badge, never for decoration. Each colour has its light and
/// dark value; there is no dynamic or wallpaper colour.
enum Palette {
    static let primary = pair(0x2E5E55, 0x95D1C2)
    static let onPrimary = pair(0xFFFFFF, 0x003730)
    static let primaryContainer = pair(0xCBE7DF, 0x15493F)
    static let onPrimaryContainer = pair(0x0B2B25, 0xB0EEDD)
    static let secondaryContainer = pair(0xD2E5DF, 0x374B45)
    static let onSecondaryContainer = pair(0x0C1F1B, 0xD2E7E0)
    /// Brass: the item number, Add to cart and the cart badge. Nothing else.
    static let tertiary = pair(0x7A5A1C, 0xEEC06E)
    static let onTertiary = pair(0xFFFFFF, 0x412D00)
    static let tertiaryContainer = pair(0xFCDFA6, 0x5D4200)
    static let onTertiaryContainer = pair(0x271900, 0xFFDEA5)
    static let error = pair(0xBA1A1A, 0xFFB4AB)
    static let surface = pair(0xF7F9F7, 0x101413)
    static let onSurface = pair(0x181C1B, 0xE0E3E1)
    static let onSurfaceVariant = pair(0x3F4946, 0xBFC9C5)
    static let outline = pair(0x6F7976, 0x899390)
    static let outlineVariant = pair(0xBFC9C5, 0x3F4946)
    static let surfaceContainerLowest = pair(0xFFFFFF, 0x0B0F0E)
    static let surfaceContainerLow = pair(0xF1F4F2, 0x181C1B)
    static let surfaceContainer = pair(0xEBEFEC, 0x1C2120)
    static let surfaceContainerHigh = pair(0xE5E9E6, 0x272B2A)
    static let inverseSurface = pair(0x2D3130, 0xE0E3E1)
    static let inverseOnSurface = pair(0xEFF1EF, 0x2D3130)
    static let inversePrimary = pair(0x95D1C2, 0x2E5E55)

    /// One tint pair per aisle: the tile behind an item's drawing, and the drawing's ink.
    static func tile(_ aisle: Aisle) -> UIColor {
        switch aisle {
        case .kitchen: pair(0xDDEBE5, 0x23332E)
        case .desk: pair(0xE2E7EE, 0x222A33)
        case .garden: pair(0xDCEBD3, 0x263322)
        case .home: pair(0xE8E4DE, 0x302D29)
        }
    }

    static func ink(_ aisle: Aisle) -> UIColor {
        switch aisle {
        case .kitchen: pair(0x2E5E55, 0x95D1C2)
        case .desk: pair(0x3F5466, 0xB4C5D8)
        case .garden: pair(0x3E6A2E, 0xA8D493)
        case .home: pair(0x5B5148, 0xD3C7BA)
        }
    }

    private static func pair(_ light: UInt32, _ dark: UInt32) -> UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? rgb(dark) : rgb(light) }
    }

    private static func rgb(_ hex: UInt32) -> UIColor {
        UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}

extension Color {
    init(_ color: UIColor) { self.init(uiColor: color) }
}

/// The type of SPEC.md §10: the system face in the iOS text styles, and the system monospace for item numbers and
/// the printed test account. Every size follows Dynamic Type.
enum Typeface {
    static let itemNumber = Font.system(.footnote, design: .monospaced).weight(.medium)
}

/// The drawings of `art/`, from the asset catalog (scripts/make-assets.swift).
enum Art {
    static func icon(_ name: String) -> Image { Image("icon-\(name)").renderingMode(.template) }
    static func glyph(_ glyph: Glyph) -> Image { Image("glyph-\(glyph.rawValue)").renderingMode(.template) }
    static func uiIcon(_ name: String) -> UIImage? { UIImage(named: "icon-\(name)")?.withRenderingMode(.alwaysTemplate) }
}

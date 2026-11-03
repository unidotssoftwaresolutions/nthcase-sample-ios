import Foundation

/// The four aisles of the shop. The key is what the form's picker stores; the label is what it shows.
public enum Aisle: String, CaseIterable, Sendable {
    case kitchen, desk, garden, home

    public var key: String { rawValue }

    public var label: String {
        switch self {
        case .kitchen: "Kitchen"
        case .desk: "Desk"
        case .garden: "Garden"
        case .home: "Home"
        }
    }
}

/// Which original line drawing an item wears. Every glyph is drawn for these apps (`art/glyphs`).
public enum Glyph: String, CaseIterable, Sendable {
    case mug, notebook, plant, candle, lamp, bottle, clock, tote, pen, bowl
}

public struct Item: Identifiable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let aisle: Aisle
    public let glyph: Glyph
    public let priceCents: Int
    public let description: String

    /// "No. 007": the item number every screen shows.
    public var number: String { itemNumber(id) }
    public var price: String { formatPrice(priceCents) }
}

public func itemNumber(_ id: Int) -> String { String(format: "No. %03d", id) }

/// Fixed US-dollar prices, so every run and every framework shows the same text.
public func formatPrice(_ cents: Int) -> String { String(format: "$%d.%02d", cents / 100, cents % 100) }

/// "1 item", "2 items".
public func itemCount(_ count: Int) -> String { count == 1 ? "1 item" : "\(count) items" }

/// The seeded catalogue: forty invented items, identical in every Mossgrove app (SPEC.md §3). Nothing is fetched;
/// the order here is the order of the list.
public enum Catalog {
    public static let items: [Item] = [
        Item(id: 1, name: "Stoneware Mug", aisle: .kitchen, glyph: .mug, priceCents: 1400, description: "A heavy, speckled mug that keeps tea warm through a long call."),
        Item(id: 2, name: "Grid Notebook", aisle: .desk, glyph: .notebook, priceCents: 950, description: "Ninety-six pages of 5 mm grid, stitched to lie flat."),
        Item(id: 3, name: "Desk Fern", aisle: .garden, glyph: .plant, priceCents: 1800, description: "A small fern in a glazed pot. Likes shade and a weekly drink."),
        Item(id: 4, name: "Cedar Candle", aisle: .home, glyph: .candle, priceCents: 1600, description: "Soy wax with a dry cedar scent. Burns for about forty hours."),
        Item(id: 5, name: "Brass Desk Lamp", aisle: .desk, glyph: .lamp, priceCents: 4200, description: "A warm, low lamp with a brass shade and a fabric cable."),
        Item(id: 6, name: "Steel Water Bottle", aisle: .kitchen, glyph: .bottle, priceCents: 2400, description: "Double-walled steel. Cold for a day, hot for half of one."),
        Item(id: 7, name: "Wall Clock", aisle: .home, glyph: .clock, priceCents: 3500, description: "A quiet sweep movement behind a plain white face."),
        Item(id: 8, name: "Canvas Tote", aisle: .home, glyph: .tote, priceCents: 2200, description: "Heavy canvas with long handles and one inside pocket."),
        Item(id: 9, name: "Fineliner Pen Set", aisle: .desk, glyph: .pen, priceCents: 1200, description: "Six fineliners in muted inks, 0.4 mm tips."),
        Item(id: 10, name: "Serving Bowl", aisle: .kitchen, glyph: .bowl, priceCents: 2800, description: "A wide stoneware bowl for salads, fruit or bread."),
        Item(id: 11, name: "Espresso Cup Pair", aisle: .kitchen, glyph: .mug, priceCents: 1900, description: "Two small cups with thick walls and saucers to match."),
        Item(id: 12, name: "Dot Journal", aisle: .desk, glyph: .notebook, priceCents: 1100, description: "Dotted pages, numbered, with two ribbon markers."),
        Item(id: 13, name: "Succulent Trio", aisle: .garden, glyph: .plant, priceCents: 2100, description: "Three hardy succulents that forgive a missed watering."),
        Item(id: 14, name: "Fig Leaf Candle", aisle: .home, glyph: .candle, priceCents: 1750, description: "Green and milky. Smells like a fig tree after rain."),
        Item(id: 15, name: "Clip Reading Lamp", aisle: .desk, glyph: .lamp, priceCents: 2900, description: "Clips to a shelf or a bed frame. Three brightness steps."),
        Item(id: 16, name: "Glass Carafe", aisle: .kitchen, glyph: .bottle, priceCents: 2600, description: "A litre of water on the table, with a cup for a lid."),
        Item(id: 17, name: "Alarm Clock", aisle: .home, glyph: .clock, priceCents: 2300, description: "A silent tick and a gentle rising alarm."),
        Item(id: 18, name: "Market Bag", aisle: .home, glyph: .tote, priceCents: 1500, description: "Folds into its own pocket. Holds a week of vegetables."),
        Item(id: 19, name: "Fountain Pen", aisle: .desk, glyph: .pen, priceCents: 3800, description: "A steel nib, a converter, and a box of blue cartridges."),
        Item(id: 20, name: "Salad Bowl", aisle: .kitchen, glyph: .bowl, priceCents: 3200, description: "Oiled wood, turned from one piece."),
        Item(id: 21, name: "Travel Mug", aisle: .kitchen, glyph: .mug, priceCents: 1800, description: "Leak-proof lid, fits a car's cup holder."),
        Item(id: 22, name: "Sketchbook", aisle: .desk, glyph: .notebook, priceCents: 1350, description: "Heavy blank paper that takes ink and light washes."),
        Item(id: 23, name: "Herb Planter", aisle: .garden, glyph: .plant, priceCents: 2700, description: "A long planter for a sunny sill. Seeds not included."),
        Item(id: 24, name: "Beeswax Taper Set", aisle: .home, glyph: .candle, priceCents: 1450, description: "Four hand-dipped tapers that burn clean and slow."),
        Item(id: 25, name: "Floor Lamp", aisle: .home, glyph: .lamp, priceCents: 8900, description: "A tall arc of steel with a linen shade."),
        Item(id: 26, name: "Oil Bottle", aisle: .kitchen, glyph: .bottle, priceCents: 1250, description: "A pourer that stops dripping when you stop pouring."),
        Item(id: 27, name: "Desk Clock", aisle: .desk, glyph: .clock, priceCents: 3100, description: "A small square clock with a date window."),
        Item(id: 28, name: "Laptop Tote", aisle: .desk, glyph: .tote, priceCents: 3600, description: "A padded sleeve with handles for a 14-inch laptop."),
        Item(id: 29, name: "Brush Pen", aisle: .desk, glyph: .pen, priceCents: 750, description: "A soft tip for lettering and quick sketches."),
        Item(id: 30, name: "Noodle Bowl", aisle: .kitchen, glyph: .bowl, priceCents: 1600, description: "Deep enough for broth, with a rest for chopsticks."),
        Item(id: 31, name: "Tea Mug", aisle: .kitchen, glyph: .mug, priceCents: 1500, description: "A tall mug with a steel infuser that sits inside."),
        Item(id: 32, name: "Pocket Notebook", aisle: .desk, glyph: .notebook, priceCents: 600, description: "Fits a back pocket. Ruled, sixty-four pages."),
        Item(id: 33, name: "Hanging Planter", aisle: .garden, glyph: .plant, priceCents: 2450, description: "A glazed pot on a cotton rope, for trailing plants."),
        Item(id: 34, name: "Pine Candle", aisle: .home, glyph: .candle, priceCents: 1600, description: "Resin and needles. Best on a cold evening."),
        Item(id: 35, name: "Bedside Lamp", aisle: .home, glyph: .lamp, priceCents: 4500, description: "A touch dimmer and a shade that does not glare."),
        Item(id: 36, name: "Vacuum Flask", aisle: .kitchen, glyph: .bottle, priceCents: 2950, description: "Keeps soup hot from breakfast until lunch."),
        Item(id: 37, name: "Kitchen Timer", aisle: .kitchen, glyph: .clock, priceCents: 1950, description: "A wind-up timer with a bell you can hear upstairs."),
        Item(id: 38, name: "Beach Tote", aisle: .home, glyph: .tote, priceCents: 2500, description: "Striped cotton that shakes clean of sand."),
        Item(id: 39, name: "Pencil Set", aisle: .desk, glyph: .pen, priceCents: 850, description: "Twelve graphite pencils, 4H to 6B."),
        Item(id: 40, name: "Fruit Bowl", aisle: .kitchen, glyph: .bowl, priceCents: 3400, description: "A wire bowl that lets fruit breathe."),
    ]

    private static let byId = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })

    public static func find(_ id: Int) -> Item? { byId[id] }

    /// The item a link or route names, as written: nil when it is not a number or not 1–40.
    public static func find(raw: String) -> Item? { Int(raw).flatMap(find) }

    /// Search by name (case-insensitive, anywhere in the name) or by number: "7", "007" and "No. 007" all find item
    /// 7. A blank query matches everything.
    public static func search(_ query: String) -> [Item] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return items }
        var digits = Substring(q)
        if digits.lowercased().hasPrefix("no.") { digits = digits.dropFirst(3) }
        let trimmed = digits.trimmingCharacters(in: .whitespaces)
        let number = !trimmed.isEmpty && trimmed.allSatisfy(\.isASCIIDigit) ? Int(trimmed) : nil
        return items.filter { $0.name.range(of: q, options: .caseInsensitive) != nil || (number != nil && $0.id == number) }
    }

    /// The Shop's count line: "40 drawers · No. 001–040", or "4 of 40 drawers" while searching.
    public static func countLine(query: String, results: Int) -> String {
        query.trimmingCharacters(in: .whitespaces).isEmpty
            ? "\(items.count) drawers · No. 001–040"
            : "\(results) of \(items.count) drawers"
    }
}

extension Character {
    var isASCIIDigit: Bool { isASCII && isNumber }
}

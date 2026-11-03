import Foundation

/// `nthcase-sample://item/{id}`: the one deep link every Mossgrove app answers (SPEC.md §5, Deep link).
public enum DeepLinks {
    public static let scheme = "nthcase-sample"
    public static let itemHost = "item"

    /// The item id as written in the link (it may be unknown or not a number; the item screen says so), or nil when
    /// the link is not an item link. Any other host or path is ignored.
    public static func itemId(_ url: URL) -> String? {
        guard url.scheme?.lowercased() == scheme, url.host?.lowercased() == itemHost else { return nil }
        let segments = url.path.split(separator: "/", omittingEmptySubsequences: true)
        guard segments.count == 1 else { return nil }
        let id = String(segments[0]).removingPercentEncoding ?? String(segments[0])
        return id.trimmingCharacters(in: .whitespaces).isEmpty ? nil : id
    }

    public static func forItem(_ id: Int) -> URL { URL(string: "\(scheme)://\(itemHost)/\(id)")! }
}

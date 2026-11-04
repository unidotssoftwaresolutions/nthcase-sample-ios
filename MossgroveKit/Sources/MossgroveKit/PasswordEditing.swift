import Foundation

/// How a hidden password takes a key (the app's PasswordField). UIKit empties a secure field on the first key of a
/// new editing session; this keeps what was typed, as every other platform does. A shown password is not edited
/// here: UIKit edits it as any field.
public enum PasswordEditing {
    /// The text after one key. `range` and `replacement` are UIKit's (`shouldChangeCharactersIn`); `sessionJustBegan`
    /// is true until the first key of an editing session (or after the dots come back). At that moment a key that
    /// would replace everything is added at the end instead, and Delete removes the last character.
    public static func apply(to current: String, range: NSRange, replacement: String, sessionJustBegan: Bool) -> String {
        let text = current as NSString
        guard range.location != NSNotFound, NSMaxRange(range) <= text.length else { return current + replacement }
        let replacesAll = range.location == 0 && range.length == text.length && text.length > 0
        if sessionJustBegan && replacesAll {
            return replacement.isEmpty ? String(current.dropLast()) : current + replacement
        }
        return text.replacingCharacters(in: range, with: replacement)
    }
}

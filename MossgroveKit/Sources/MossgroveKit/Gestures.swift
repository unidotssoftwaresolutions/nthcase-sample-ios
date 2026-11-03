import Foundation

/// The status words of the gestures screen. They are the spec's oracle: the same words on every framework.
public enum GestureWords {
    public static let ready = "Ready"
    public static let tapped = "Tapped"
    public static let doubleTapped = "Double-tapped"
    public static let longPressed = "Long-pressed"
    public static func swiped(_ direction: SwipeDirection) -> String { "Swiped \(direction.rawValue)" }
    public static let dropped = "Dropped on the drawer"
    public static let dropMissed = "Dropped outside the drawer"
    public static let pinchedOut = "Pinched out"
    public static let pinchedIn = "Pinched in"
    public static let rotatedClockwise = "Rotated clockwise"
    public static let rotatedCounterClockwise = "Rotated counter-clockwise"
    public static let scrolledTo = "Found the bottom drawer"
    public static let shaken = "Shaken"

    public static func taps(_ count: Int) -> String { "Taps: \(count)" }
    public static func zoom(_ scale: Double) -> String { String(format: "Zoom %.1f×", scale) }
    public static func rotation(_ degrees: Double) -> String { "Rotation \(Int(degrees.rounded()))°" }
}

public enum SwipeDirection: String, CaseIterable, Sendable {
    case left, right, up, down
}

public enum GestureRules {
    /// A swipe must travel at least this far (points), along its longest axis.
    public static let minSwipe = 48.0
    /// A long press holds at least this long.
    public static let longPressSeconds = 0.5
    /// A pinch counts when the total scale changes by more than 5 %.
    public static let pinchThreshold = 0.05
    /// A two-finger rotation counts beyond 10°.
    public static let rotationThreshold = 10.0

    /// A swipe's direction from its total travel (y grows downwards); nil when it travelled less than [minSwipe].
    public static func swipeDirection(dx: Double, dy: Double, minimum: Double = minSwipe) -> SwipeDirection? {
        if max(abs(dx), abs(dy)) < minimum { return nil }
        if abs(dx) >= abs(dy) { return dx > 0 ? .right : .left }
        return dy > 0 ? .down : .up
    }

    /// "Pinched out" / "Pinched in" for a finished pinch of total `scale`, or nil when it changed 5 % or less.
    public static func pinchWord(scale: Double) -> String? {
        if scale > 1 + pinchThreshold { return GestureWords.pinchedOut }
        if scale < 1 - pinchThreshold { return GestureWords.pinchedIn }
        return nil
    }

    /// The pad's zoom after a pinch, kept within 0.5–3×.
    public static func zoom(after current: Double, scale: Double) -> Double { min(max(current * scale, 0.5), 3) }

    /// "Rotated clockwise" / "Rotated counter-clockwise" for a finished rotation (degrees, clockwise positive), or nil
    /// when it turned 10° or less.
    public static func rotationWord(degrees: Double) -> String? {
        if abs(degrees) <= rotationThreshold { return nil }
        return degrees > 0 ? GestureWords.rotatedClockwise : GestureWords.rotatedCounterClockwise
    }

    /// The pad's rotation after a turn, within one revolution.
    public static func rotation(after current: Double, degrees: Double) -> Double {
        (current + degrees).truncatingRemainder(dividingBy: 360)
    }
}

/// A shake. The spec's rule is three jolts above 2.5 g within one second, so a phone's accelerometer can be fed to
/// [onReading]. iOS also reports its own shake (`motionEnded(.motionShake)`), which is what the Simulator's Shake and
/// NthCase's `shake` produce; [onSystemShake] takes that. Either one says "Shaken".
public final class ShakeDetector {
    public static let thresholdG = 2.5
    public static let windowSeconds = 1.0
    public static let jolts = 3

    private var times: [Double] = []
    private let onShake: () -> Void

    public init(onShake: @escaping () -> Void) { self.onShake = onShake }

    /// One accelerometer reading, in g (as Core Motion reports it), at `time` seconds.
    public func onReading(x: Double, y: Double, z: Double, time: Double) {
        let g = (x * x + y * y + z * z).squareRoot()
        guard g >= Self.thresholdG else { return }
        times.append(time)
        times.removeAll { time - $0 > Self.windowSeconds }
        if times.count >= Self.jolts {
            times.removeAll()
            onShake()
        }
    }

    /// The system's own shake, from `motionEnded(_:with:)`.
    public func onSystemShake() {
        times.removeAll()
        onShake()
    }
}

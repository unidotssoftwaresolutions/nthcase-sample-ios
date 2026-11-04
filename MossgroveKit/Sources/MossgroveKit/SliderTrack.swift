import CoreGraphics
import Foundation

/// The budget slider's geometry and steps (the app's `StepSlider`), and the drag that sets it.
///
/// **How XCUITest sets a slider.** `adjust(toNormalizedSliderPosition:)`, which WebDriverAgent calls when NthCase's
/// `slide` sets a slider, reads no frame. It reads three accessibility attributes of the slider: its lowest and
/// highest scrubber positions and its current value as a fraction. Then it presses at
/// `min + f·(max − min) + (0.5 − f)·14.5` for the current fraction, holds 0.25 s, drags to the same point for the
/// new fraction at 500 points a second, and lifts there at once (`XCUIAutomation`, `_iOSSliderAdjustmentEvent…`;
/// the fourth CI run's recorded drags match it to the hundredth of a point). So XCUITest assumes the thumb's centre
/// travels from 7.25 points inside the lowest scrubber position to 7.25 points inside the highest.
///
/// **What UIKit reports.** For a `UISlider` the scrubber positions are the ends of its track (by default its bounds),
/// at mid-height, even when the slider overrides its accessibility frame (measured on this Mac with UIKit's own
/// accessibility code). An iOS 26 thumb is 37 points wide, so its centre travels from 18.5 points inside: not where
/// XCUITest presses.
///
/// **What the app does.** Its thumb is `xcuiThumbWidth` wide, so the thumb's centre travels exactly where XCUITest
/// assumes, and the value follows the finger alone (`fraction`): nothing moves the thumb after the finger lifts.
public enum SliderTrack {
    /// Half of the 14.5 points XCUITest takes off the scrubber span: where it assumes the thumb's centre stops.
    public static let xcuiInset: CGFloat = 7.25

    /// Where XCUITest touches to put a slider at `fraction`, from the scrubber positions UIKit reports.
    public static func xcuiTouch(fraction: Double, minX: Double, maxX: Double) -> Double {
        minX + fraction * (maxX - minX) + (0.5 - fraction) * 14.5
    }

    /// The thumb width that puts the thumb's centre where XCUITest presses. UIKit's thumb travels from half its width
    /// inside each end of the track, and UIKit reports the track's ends as the scrubber positions (measured on this
    /// Mac: a wider track moves the scrubbers with it), so only the thumb's width can close the gap: 14.5 points.
    public static let xcuiThumbWidth: CGFloat = 2 * xcuiInset

    /// The thumb's travel as a frame: from its centre at the lowest value to its centre at the highest, at full height.
    public static func travel(lowCentre: CGFloat, highCentre: CGFloat, height: CGFloat) -> CGRect {
        CGRect(x: lowCentre, y: 0, width: max(highCentre - lowCentre, 1), height: height)
    }

    /// The fraction (0...1) for a finger at `fingerX`, on a travel from `low` to `high` (the thumb's centre at the
    /// lowest and highest values). `grab` is how far right of the thumb's centre the finger came down when it came
    /// down on the thumb (0 when it came down on the track), so a thumb held off-centre does not jump.
    public static func fraction(fingerX: Double, grab: Double, low: Double, high: Double) -> Double {
        guard high > low else { return 0 }
        return min(max((fingerX - grab - low) / (high - low), 0), 1)
    }

    /// A value rounded to the nearest step from the range's start, and kept in the range. Halfway rounds up, as
    /// `rounded()` does.
    public static func snapped(_ value: Double, range: ClosedRange<Double>, step: Double) -> Double {
        guard step > 0 else { return min(max(value, range.lowerBound), range.upperBound) }
        let steps = ((value - range.lowerBound) / step).rounded()
        return min(max(range.lowerBound + steps * step, range.lowerBound), range.upperBound)
    }

    /// Where XCUITest's drag leaves a slider whose bounds run from `minX` to `maxX` and whose thumb's centre travels
    /// from `low` to `high`, when the thumb follows the finger and keeps where it was grabbed: from `from` to `to`
    /// (both fractions). `push` moves the end that many points further in the drag's direction, as the fourth CI
    /// run's iOS 26 `UISlider` did after a lift at speed.
    public static func xcuiDrag(from: Double, to: Double, minX: Double, maxX: Double, low: Double, high: Double,
                                push: Double = 0) -> Double {
        let start = xcuiTouch(fraction: from, minX: minX, maxX: maxX)
        let end = xcuiTouch(fraction: to, minX: minX, maxX: maxX)
        let thumb = low + from * (high - low)
        let grab = start - thumb
        let direction: Double = end > start ? 1 : (end < start ? -1 : 0)
        return fraction(fingerX: end + direction * push, grab: grab, low: low, high: high)
    }
}

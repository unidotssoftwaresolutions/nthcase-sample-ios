import CoreGraphics
import Foundation

/// The budget slider's geometry and steps (the app's `StepSlider`).
///
/// XCUITest's `adjust(toNormalizedSliderPosition:)`, which WebDriverAgent calls when NthCase's `slide` sets a slider,
/// drags the thumb from its place to that fraction of the element's frame. A slider's thumb moves by the drag's
/// distance, and its centre travels a shorter way than the frame, by the thumb's width. So on a frame wider than the
/// travel the drag overshoots (`dragOnAFrame` works it out): 0.6 from $50 gave $130 in the third CI run, not $120.
/// When the frame Appium reads IS the travel, from the thumb's centre at the lowest value to its centre at the
/// highest, the drag lands where the fraction says.
public enum SliderTrack {
    /// The thumb's travel as a frame: from its centre at the lowest value to its centre at the highest, at full height.
    public static func travel(lowCentre: CGFloat, highCentre: CGFloat, height: CGFloat) -> CGRect {
        CGRect(x: lowCentre, y: 0, width: max(highCentre - lowCentre, 1), height: height)
    }

    /// A value rounded to the nearest step from the range's start, and kept in the range. Halfway rounds up, as
    /// `rounded()` does.
    public static func snapped(_ value: Double, range: ClosedRange<Double>, step: Double) -> Double {
        guard step > 0 else { return min(max(value, range.lowerBound), range.upperBound) }
        let steps = ((value - range.lowerBound) / step).rounded()
        return min(max(range.lowerBound + steps * step, range.lowerBound), range.upperBound)
    }

    /// Where `adjust(toNormalizedSliderPosition: to)` leaves a slider whose value is at `from` (both 0...1 of the range),
    /// when the element's frame is `frameWidth` wide and the thumb's centre travels `travelWidth` of it, centred:
    /// the drag goes from the point `from` of the frame to the point `to` of the frame, and the thumb follows it from
    /// where it was grabbed. With the frame equal to the travel, it is `to`.
    public static func dragOnAFrame(from: Double, to: Double, frameWidth: Double, travelWidth: Double) -> Double {
        guard travelWidth > 0 else { return from }
        let inset = (frameWidth - travelWidth) / 2
        let grabbedAt = from * frameWidth                 // where the drag starts, on the frame
        let thumbCentre = inset + from * travelWidth      // where the thumb's centre is
        let offset = grabbedAt - thumbCentre              // kept while the thumb follows the touch
        let endCentre = to * frameWidth - offset
        return min(max((endCentre - inset) / travelWidth, 0), 1)
    }
}

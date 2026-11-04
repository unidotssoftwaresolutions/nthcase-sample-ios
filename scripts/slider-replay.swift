// The budget slider, as XCUITest's adjust(toNormalizedSliderPosition:) sets it, on this Mac.
//
// Built by scripts/slider-replay.sh as a Mac Catalyst app (UIKit's own UISlider and its own accessibility code, the
// same UIKit release as iOS 26), with the app's TravelSlider cut from Mossgrove/Components/Components.swift. It reads
// the scrubber positions and the current value the way XCUITest does, presses where XCUITest presses
// (SliderTrack.xcuiTouch), and plays the drag through the slider's own touch handling. It prints the six slides of
// FlowTests.testTheBudgetLandsWhereSlideSetsIt and how many of 441 slides (every start, every step) land, and exits
// 1 if any does not. It opens no window on screen and quits by itself. Not part of the app.
import UIKit
import ObjectiveC
setvbuf(stdout, nil, _IONBF, 0)
_ = Bundle(path: "/System/iOSSupport/System/Library/AccessibilityBundles/UIKit.axbundle")!.load()
let ax: AnyClass = NSClassFromString("UISliderAccessibility")!
func axPoint(_ o: AnyObject, _ n: String) -> CGPoint {
    let s = NSSelectorFromString(n); return unsafeBitCast(class_getMethodImplementation(ax, s)!, to: (@convention(c) (AnyObject, Selector) -> CGPoint).self)(o, s)
}
func axNumber(_ o: AnyObject, _ n: String) -> Double {
    let s = NSSelectorFromString(n); return (unsafeBitCast(class_getMethodImplementation(ax, s)!, to: (@convention(c) (AnyObject, Selector) -> AnyObject?).self)(o, s) as? NSNumber)?.doubleValue ?? .nan
}
final class FakeTouch: UITouch {
    var now = CGPoint.zero; weak var host: UIView?
    override func location(in view: UIView?) -> CGPoint { host!.convert(now, to: view) }
}
final class Snapper: NSObject {   // the app's Coordinator.changed
    @objc func changed(_ s: UISlider) { let v = (Double(s.value) / 10).rounded() * 10; if Float(v) != s.value { s.value = Float(v) } }
}
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?; let snapper = Snapper()
    func application(_ a: UIApplication, didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 874)); self.window = window
        let host = UIViewController().view!; host.frame = window.bounds; window.addSubview(host)
        let s = TravelSlider(frame: CGRect(x: 16, y: 736, width: 370, height: 44))   // the form: 16 in, 370 wide
        s.minimumValue = 0; s.maximumValue = 200; s.value = 50
        let thumb = TravelSlider.thumbImage(); s.setThumbImage(thumb, for: .normal); s.setThumbImage(thumb, for: .highlighted)
        s.addTarget(snapper, action: #selector(Snapper.changed(_:)), for: .valueChanged)
        host.addSubview(s); s.layoutIfNeeded()
        let lo = axPoint(s, "_accessibilityMinScrubberPosition"), hi = axPoint(s, "_accessibilityMaxScrubberPosition")
        let travel = s.travel
        print("scrubbers \(lo.x) ... \(hi.x); thumb centre \(16 + travel.minX) ... \(16 + travel.maxX), thumb \(s.thumbRect(forBounds: s.bounds, trackRect: s.trackRect(forBounds: s.bounds), value: 0).size); XCUITest presses \(SliderTrack.xcuiTouch(fraction: 0, minX: lo.x, maxX: hi.x)) ... \(SliderTrack.xcuiTouch(fraction: 1, minX: lo.x, maxX: hi.x))")
        func slide(_ f: Double) -> Float {
            let from = axNumber(s, "_accessibilityAbsoluteValue")
            let sx = SliderTrack.xcuiTouch(fraction: from, minX: lo.x, maxX: hi.x), ex = SliderTrack.xcuiTouch(fraction: f, minX: lo.x, maxX: hi.x)
            let t = FakeTouch(); t.host = host; t.now = CGPoint(x: sx, y: lo.y)
            s.touchesBegan([t], with: nil)
            let n = max(1, Int((abs(ex - sx) / 500 * 60).rounded(.up)))
            for i in 1...n { t.now = CGPoint(x: sx + (ex - sx) * Double(i) / Double(n), y: lo.y); s.touchesMoved([t], with: nil) }
            s.touchesEnded([t], with: nil)
            return s.value
        }
        var six: [String] = []
        for f in [0.6, 0.3, 1.0, 0.0, 0.45, 0.6] { six.append("\(f) → $\(Int(slide(f)))") }
        print("the six slides: " + six.joined(separator: ", "))
        var wrong = 0
        var shown = 0
        for a in 0...20 { for b in 0...20 { s.value = Float(a * 10); let got = slide(Double(b) / 20); if abs(got - Float(b * 10)) >= 0.01 { wrong += 1; if shown < 12 { shown += 1; print("from $\(a*10) to \(Double(b)/20): $\(Int(got))") } } } }
        print("every start to every step: \(441 - wrong) of 441 land")
        exit(wrong == 0 ? 0 : 1)
    }
}
UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(AppDelegate.self))

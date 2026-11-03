import CoreMotion
import MossgroveKit
import SwiftUI
import UIKit

/// Every gesture NthCase plays, each on its own pad. The status line pinned at the top names the last one, in the
/// spec's words (GestureWords). Each pad also offers its gesture as an accessibility action.
struct GesturesView: View {
    @State private var status = GestureWords.ready
    @State private var taps = 0
    @State private var zoom = 1.0
    @State private var rotation = 0.0
    @State private var dragOffset = CGSize.zero
    @State private var labelFrame = CGRect.zero
    @State private var drawerFrame = CGRect.zero
    @State private var dropped = false

    var body: some View {
        GeometryReader { screen in
            VStack(spacing: 0) {
                // Pinned above the scrolling pads, so the status is on screen after any gesture.
                HStack {
                    Text(status)
                        .font(.headline)
                        .accessibilityIdentifier(TestIds.gesturesStatus)
                    Spacer()
                    Text(screen.size.width > screen.size.height ? Texts.landscape : Texts.portrait)
                        .font(.subheadline.weight(.medium))
                        .accessibilityIdentifier(TestIds.gesturesOrientation)
                }
                .foregroundStyle(Color(Palette.onSecondaryContainer))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(Palette.secondaryContainer))

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            tapPad
                            doubleTapPad
                            longPressPad
                        }
                        swipePad
                        dragAndDrop
                        HStack(spacing: 12) {
                            pinchPad
                            rotatePad
                        }
                        Text(Texts.scrollHint).font(.subheadline).foregroundStyle(Color(Palette.onSurfaceVariant))
                        ForEach(1...12, id: \.self) { shelf in
                            Text("Shelf \(shelf)")
                                .foregroundStyle(Color(Palette.onSurfaceVariant))
                                .padding(16)
                                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                                .background(Color(Palette.surfaceContainer), in: RoundedRectangle(cornerRadius: 12))
                        }
                        Button(Texts.openBottomDrawer) { status = GestureWords.scrolledTo }
                            .buttonStyle(FilledButtonStyle())
                            .accessibilityIdentifier(TestIds.gesturesScrollTarget)
                    }
                    .foregroundStyle(Color(Palette.onSurface))
                    .padding(16)
                }
                .accessibilityIdentifier(TestIds.gesturesScroll)
            }
        }
        .screenBackground()
        .background { ShakeCatcher { status = GestureWords.shaken } }
        .container(TestIds.gesturesScreen)
        .topBar("Gestures", back: true)
    }

    // MARK: Pads

    /// The pad holds its title and its count as separate elements, so `gestures_tap_count` keeps its id.
    private var tapPad: some View {
        Pad(title: "Tap", hint: GestureWords.taps(taps), hintId: TestIds.gesturesTapCount, titleAction: tap)
            .onTapGesture(perform: tap)
            .container(TestIds.gesturesTap)
    }

    private func tap() {
        taps += 1
        status = GestureWords.tapped
    }

    private var doubleTapPad: some View {
        Pad(title: "Double tap", hint: "Twice, quickly")
            .onTapGesture(count: 2) { status = GestureWords.doubleTapped }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(named: "Double tap") { status = GestureWords.doubleTapped }
            .accessibilityIdentifier(TestIds.gesturesDoubleTap)
    }

    private var longPressPad: some View {
        Pad(title: "Long press", hint: "Hold for a moment")
            .onLongPressGesture(minimumDuration: GestureRules.longPressSeconds) { status = GestureWords.longPressed }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(named: "Long press") { status = GestureWords.longPressed }
            .accessibilityIdentifier(TestIds.gesturesLongPress)
    }

    private var swipePad: some View {
        VStack(spacing: 2) {
            Text("Swipe").font(.subheadline.weight(.semibold))
            Text("Left, right, up or down").font(.caption).foregroundStyle(Color(Palette.onSurfaceVariant))
        }
        .frame(maxWidth: .infinity, minHeight: 140)
        .padStyle()
        // high priority, so a vertical swipe on the pad is the pad's and does not scroll the page
        .highPriorityGesture(
            DragGesture(minimumDistance: 10).onEnded { drag in
                if let direction = GestureRules.swipeDirection(dx: drag.translation.width, dy: drag.translation.height) {
                    status = GestureWords.swiped(direction)
                }
            }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Swipe pad")
        .accessibilityActions {
            ForEach(SwipeDirection.allCases, id: \.self) { direction in
                Button("Swipe \(direction.rawValue)") { status = GestureWords.swiped(direction) }
            }
        }
        .accessibilityIdentifier(TestIds.gesturesSwipe)
    }

    private var dragAndDrop: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Drag the label onto the drawer").font(.subheadline.weight(.semibold))
            HStack(spacing: 24) {
                Text(itemNumber(7))
                    .font(Typeface.itemNumber)
                    .foregroundStyle(Color(Palette.onTertiaryContainer))
                    .frame(width: 120, height: 56)
                    .background(Color(Palette.tertiaryContainer), in: RoundedRectangle(cornerRadius: 4))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(Palette.tertiary), lineWidth: 1))
                    // where the label rests: measured only while it is not being dragged
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { if dragOffset == .zero { labelFrame = $0 } }
                    .offset(dragOffset)
                    .zIndex(1)
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 4, coordinateSpace: .global)
                            .onChanged { dragOffset = $0.translation }
                            .onEnded { drag in
                                let centre = CGPoint(x: labelFrame.midX + drag.translation.width, y: labelFrame.midY + drag.translation.height)
                                let hit = drawerFrame.contains(centre)
                                if hit { dropped = true }
                                status = hit ? GestureWords.dropped : GestureWords.dropMissed
                                dragOffset = .zero
                            }
                    )
                    .accessibilityLabel("Label \(itemNumber(7))")
                    .accessibilityAction(named: "Drop on the drawer") {
                        dropped = true
                        status = GestureWords.dropped
                    }
                    .accessibilityIdentifier(TestIds.gesturesDragSource)
                HStack(spacing: 4) {
                    if dropped { Art.icon("check").resizable().frame(width: 18, height: 18) }
                    Text(dropped ? "Labelled" : "Drawer")
                }
                .frame(maxWidth: .infinity, minHeight: 96)
                .background(dropped ? Color(Palette.primaryContainer) : Color(Palette.surfaceContainerLow), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(Palette.outline), lineWidth: 2))
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { drawerFrame = $0 }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(dropped ? "Drawer, labelled" : "Drawer, no label")
                .accessibilityIdentifier(TestIds.gesturesDropTarget)
            }
        }
    }

    private var pinchPad: some View {
        TwoFingerPad(title: "Pinch", value: GestureWords.zoom(zoom), valueId: TestIds.gesturesZoomValue, scale: zoom, angle: 0)
            .gesture(
                MagnifyGesture().onEnded { pinch in
                    let scale = Double(pinch.magnification)
                    if let word = GestureRules.pinchWord(scale: scale) {
                        zoom = GestureRules.zoom(after: zoom, scale: scale)
                        status = word
                    }
                }
            )
            .container(TestIds.gesturesPinch)
    }

    private var rotatePad: some View {
        TwoFingerPad(title: "Rotate", value: GestureWords.rotation(rotation), valueId: TestIds.gesturesRotationValue, scale: 1, angle: rotation)
            .gesture(
                RotateGesture().onEnded { turn in
                    let degrees = turn.rotation.degrees
                    if let word = GestureRules.rotationWord(degrees: degrees) {
                        rotation = GestureRules.rotation(after: rotation, degrees: degrees)
                        status = word
                    }
                }
            )
            .container(TestIds.gesturesRotate)
    }
}

/// A gesture pad: a drawer-front panel with a title and one line under it.
private struct Pad: View {
    let title: String
    let hint: String
    var hintId: String?
    var titleAction: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let titleAction {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction(.default) { titleAction() }
            } else {
                Text(title).font(.subheadline.weight(.semibold))
            }
            Text(hint).font(.caption).foregroundStyle(Color(Palette.onSurfaceVariant)).testId(hintId)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
        .padStyle()
    }
}

/// A pad for a two-finger gesture: a green square that scales or turns with it, and its value.
private struct TwoFingerPad: View {
    let title: String
    let value: String
    let valueId: String
    let scale: Double
    let angle: Double

    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.subheadline.weight(.semibold))
            Spacer()
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(Palette.primary))
                .frame(width: 48, height: 48)
                .scaleEffect(scale)
                .rotationEffect(.degrees(angle))
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
            Spacer()
            Text(value).font(.caption).accessibilityIdentifier(valueId)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
        .padStyle()
        .accessibilityLabel("\(title) pad")
    }
}

private extension View {
    func padStyle() -> some View {
        padding(12)
            .background(Color(Palette.surfaceContainerLow), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(Palette.outlineVariant), lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// The shake. iOS's own (`motionEnded`), which the Simulator's Shake and NthCase's `shake` produce, and the spec's
/// three jolts over 2.5 g within 1 s from the accelerometer on a phone. It listens only while Gestures is shown.
struct ShakeCatcher: UIViewControllerRepresentable {
    let onShake: () -> Void

    func makeUIViewController(context: Context) -> Catcher { Catcher(onShake: onShake) }

    func updateUIViewController(_ catcher: Catcher, context: Context) { catcher.onShake = onShake }

    final class Catcher: UIViewController {
        var onShake: () -> Void
        private lazy var detector = ShakeDetector { [weak self] in self?.onShake() }
        private let motion = CMMotionManager()

        init(onShake: @escaping () -> Void) {
            self.onShake = onShake
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("not from a storyboard") }

        override func loadView() {
            view = UIView()
            view.isUserInteractionEnabled = false
        }

        override var canBecomeFirstResponder: Bool { true }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            becomeFirstResponder()
            guard motion.isAccelerometerAvailable else { return }
            motion.accelerometerUpdateInterval = 1.0 / 50
            motion.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
                guard let a = data?.acceleration, let time = data?.timestamp else { return }
                self?.detector.onReading(x: a.x, y: a.y, z: a.z, time: time)
            }
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            motion.stopAccelerometerUpdates()
            resignFirstResponder()
        }

        override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
            if motion == .motionShake { detector.onSystemShake() } else { super.motionEnded(motion, with: event) }
        }
    }
}

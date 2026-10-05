import AppKit
import ScreenSaver

// Deals styles for Random: every style once in a new order, never the same twice in a row.
private struct StyleDeck {
    private var bag: [DrawStyle] = []
    private(set) var current = DrawStyle.sweep

    mutating func next(_ chosen: DrawStyle) -> DrawStyle {
        guard chosen == .random else {
            current = chosen
            return chosen
        }
        if bag.isEmpty {
            bag = DrawStyle.animated.shuffled()
            if bag.last == current { bag.swapAt(0, bag.count - 1) }
        }
        current = bag.removeLast()
        return current
    }
}

@objc(StripesView)
final class StripesView: ScreenSaverView {
    // Seconds on a monotonic clock. The frame renderer replaces it to step time by hand.
    static var clock: () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }

    // Seconds each location stays complete between its build in and build out.
    private let hold: TimeInterval = 15

    private var locations: [Location] = []
    private var chosenIn = DrawStyle.sweep
    private var chosenOut = DrawStyle.fade
    private var decks = (in: StyleDeck(), out: StyleDeck())

    // The styles for the current location; differ from the chosen ones only for Random.
    private var styleIn = DrawStyle.sweep
    private var styleOut = DrawStyle.fade

    // Seconds for the build in, and again for the build out.
    private var duration: TimeInterval = 14
    private var showLabel = true
    private var labelFont = Settings.systemMono
    private var labelSize: CGFloat = 24

    private var index = 0

    // Which corner holds the label: 0 bottom-left, then clockwise. Moves with each location
    // so no pixels show the same text every cycle.
    private var corner = 0
    private var start: TimeInterval = 0

    // Whether the finished picture is on screen, so frames during the hold can be skipped.
    private var drewStill = false

    // The rank at which each year, or each mosaic tile, appears and is later erased.
    private var order: [Int] = []
    private var tileOrder: [Int] = []
    private let mosaicRows = 12
    private let blindSlats = 20
    private var options: OptionsSheet?

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        log.info("view created, preview=\(self.isPreview), pid=\(getpid())")
        animationTimeInterval = 1.0 / 30
        apply(Settings.current)
    }

    // Since macOS 14 the host does not always stop a view when the screen saver ends. A view
    // whose window has gone stops animating, so leftover views do not keep drawing.
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil, isAnimating {
            log.info("window gone, stopping, preview=\(self.isPreview)")
            stopAnimation()
        }
    }

    func apply(_ s: Settings) {
        locations = Locations.selected(s.selection)
        chosenIn = s.style
        chosenOut = s.exitStyle
        decks = (StyleDeck(), StyleDeck())
        duration = s.drawIn
        showLabel = s.showLabel
        labelFont = s.labelFont
        labelSize = s.labelSize
        show(0)
    }

    private func show(_ i: Int) {
        index = locations.isEmpty ? 0 : i % locations.count
        start = Self.clock()
        drewStill = false
        let n = locations.isEmpty ? 0 : locations[index].stripes.count
        order = Array(0..<n).shuffled()
        tileOrder = Array(0..<(n * mosaicRows)).shuffled()
        styleIn = decks.in.next(chosenIn)
        styleOut = decks.out.next(chosenOut)
        corner = (corner + 1) % 4
    }

    override func startAnimation() {
        super.startAnimation()
        show(index)
    }

    override func animateOneFrame() {
        let t = Self.clock() - start
        if t > duration + hold + duration {
            show(index + 1)
        }

        // During the hold nothing moves, so draw its first frame and skip the rest.
        let still = t >= duration && t <= duration + hold
        guard !(still && drewStill) else { return }
        drewStill = still
        needsDisplay = true
    }

    override var isOpaque: Bool { true }

    override func draw(_ rect: NSRect) {
        NSColor.black.setFill()
        bounds.fill()
        guard !locations.isEmpty else { return }

        let loc = locations[index]
        let n = Double(loc.stripes.count)
        let t = Self.clock() - start
        let building = t < duration + hold

        if building {
            paint(loc, styleIn, progress: min(1, t / duration), erase: false)
        } else {
            // The build out replays its style in black over the finished picture.
            let e = min(1, (t - duration - hold) / duration)
            paint(loc, .fade, progress: 1, erase: false)
            paint(loc, styleOut, progress: e, erase: true)
        }

        guard showLabel else { return }
        if building {
            let p = min(1, t / duration)
            let lead: Double
            switch styleIn {
            case .sweep: lead = p * n
            case .rise, .drop, .flip: lead = p * (n + wave(styleIn, n))
            default: lead = n
            }
            drawLabel(loc, year: loc.firstYear + max(0, min(Int(n), Int(lead.rounded(.up))) - 1), alpha: 1)
        } else {
            let e = min(1, (t - duration - hold) / duration)
            drawLabel(loc, year: loc.firstYear + Int(n) - 1, alpha: 1 - smooth(e))
        }
    }

    // How many stripes are in motion at once, for the styles that move across the screen.
    private func wave(_ style: DrawStyle, _ n: Double) -> Double {
        switch style {
        case .rise: max(1, n / 4)
        case .drop: max(1, n / 14)
        case .flip: max(1, n / 8)
        default: max(1, n / 20)
        }
    }

    // Draws a location at progress p through a style. When erasing, the same motion paints black.
    private func paint(_ loc: Location, _ style: DrawStyle, progress p: Double, erase: Bool) {
        let palette = Locations.palette
        let n = Double(loc.stripes.count)
        let h = bounds.height
        let width = bounds.width / CGFloat(n)
        let wave = wave(style, n)
        let colorOf = { (i: Int) in erase ? NSColor.black : palette[Int(loc.stripes[i])] }

        // Progress of stripe x through its own part of a left-to-right wave.
        func waveAt(_ x: Double) -> Double {
            clamp((p * (n + wave) - x) / wave)
        }

        if style == .blinds {
            drawBlinds(loc, progress: p, colorOf: colorOf)
            return
        }

        if style == .iris {
            let r = smooth(p) * hypot(bounds.width, h) / 2
            NSGraphicsContext.saveGraphicsState()
            NSBezierPath(ovalIn: NSRect(x: bounds.midX - r, y: bounds.midY - r, width: 2 * r, height: 2 * r)).addClip()
        }

        for i in 0..<loc.stripes.count {
            let x = Double(i)
            let color = colorOf(i)

            // Round edges to whole pixels so neighbouring stripes don't leave seams.
            let x0 = (CGFloat(i) * width).rounded()
            let x1 = (CGFloat(i + 1) * width).rounded()
            let full = NSRect(x: x0, y: 0, width: x1 - x0, height: h)

            switch style {
            case .sweep:
                fill(full, color, alpha: clamp(p * n - x))
            case .rise:
                fill(NSRect(x: x0, y: 0, width: x1 - x0, height: (h * smooth(waveAt(x))).rounded()), color, alpha: 1)
            case .scatter:
                fill(full, color, alpha: clamp((p * (n + wave) - Double(order[i])) / wave))
            case .fade:
                fill(full, color, alpha: smooth(p))
            case .iris:
                fill(full, color, alpha: p > 0 ? 1 : 0)
            case .blinds, .random:
                break
            case .drop:
                let q = waveAt(x)
                guard q > 0 else { continue }
                fill(full.offsetBy(dx: 0, dy: (h * (1 - dropFall(q))).rounded()), color, alpha: 1)
            case .flip:
                // The stripe turns about its center line, darker while it is edge-on.
                let q = smooth(waveAt(x))
                let w = (x1 - x0) * q
                fill(NSRect(x: (x0 + x1 - w) / 2, y: 0, width: w, height: h),
                     color.blended(withFraction: 0.6 * (1 - q), of: .black) ?? color, alpha: 1)
            case .mosaic:
                let cells = n * Double(mosaicRows)
                let tile = h / CGFloat(mosaicRows)
                for row in 0..<mosaicRows {
                    let rank = Double(tileOrder[i * mosaicRows + row])
                    let a = clamp((p * (cells + cells / 20) - rank) / (cells / 20))
                    let y0 = (CGFloat(row) * tile).rounded()
                    let y1 = (CGFloat(row + 1) * tile).rounded()
                    fill(NSRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0), color, alpha: a)
                }
            }
        }

        if style == .iris {
            NSGraphicsContext.restoreGraphicsState()
        }
    }

    private func fill(_ rect: NSRect, _ color: NSColor, alpha: Double) {
        guard alpha > 0, rect.width > 0, rect.height > 0 else { return }
        color.withAlphaComponent(alpha).setFill()
        rect.fill()
    }

    // Keynote's Blinds: vertical slats swing from edge-on to face the viewer, in perspective.
    // Rotation about a vertical axis keeps vertical lines vertical, so each stripe's part
    // of a slat projects to a quadrilateral with vertical sides.
    private func drawBlinds(_ loc: Location, progress p: Double, colorOf: (Int) -> NSColor) {
        let n = loc.stripes.count
        let h = bounds.height
        let slat = bounds.width / CGFloat(blindSlats)
        let stripe = bounds.width / CGFloat(n)
        let focal = h

        for k in 0..<blindSlats {
            // Each slat turns in 30% of the draw-in time; start times spread over the rest.
            let q = smooth(clamp((p - 0.7 * Double(k) / Double(blindSlats - 1)) / 0.3))
            guard q > 0 else { continue }
            let angle = (1 - q) * .pi / 2
            let cosA = CGFloat(cos(angle)), sinA = CGFloat(sin(angle))
            let left = CGFloat(k) * slat
            let center = left + slat / 2

            // Screen x and half-height of the slat's vertical line that sits at x when flat.
            func project(_ x: CGFloat) -> (x: CGFloat, half: CGFloat) {
                let u = x - center
                let scale = focal / (focal + u * sinA)
                return (center + u * cosA * scale, h / 2 * scale)
            }

            let first = max(0, Int(left / stripe))
            let last = min(n - 1, Int((left + slat) / stripe))
            for i in first...last {
                let x0 = max(left, CGFloat(i) * stripe)
                let x1 = min(left + slat, CGFloat(i + 1) * stripe)
                guard x1 > x0 else { continue }
                let a = project(x0), b = project(x1)

                // Overlap the next quad by half a pixel so antialiasing leaves no seams.
                let bx = b.x + 0.5
                let path = NSBezierPath()
                path.move(to: NSPoint(x: a.x, y: h / 2 - a.half))
                path.line(to: NSPoint(x: bx, y: h / 2 - b.half))
                path.line(to: NSPoint(x: bx, y: h / 2 + b.half))
                path.line(to: NSPoint(x: a.x, y: h / 2 + a.half))
                path.close()

                let color = colorOf(i)
                (color.blended(withFraction: 0.6 * (1 - q), of: .black) ?? color).setFill()
                path.fill()
            }
        }
    }

    // Position of a dropped stripe: a fall under gravity, then two quick, low bounces
    // whose durations follow from their heights.
    private func dropFall(_ t: Double) -> Double {
        let h1 = 0.06, h2 = 0.015
        let b1 = 2 * h1.squareRoot(), b2 = 2 * h2.squareRoot()
        var u = t * (1 + b1 + b2)
        if u < 1 { return u * u }
        u -= 1
        if u < b1 { let v = u - b1 / 2; return 1 - (h1 - v * v) }
        u -= b1
        if u < b2 { let v = u - b2 / 2; return 1 - (h2 - v * v) }
        return 1
    }

    private func clamp(_ v: Double) -> Double {
        min(1, max(0, v))
    }

    private func smooth(_ v: Double) -> Double {
        v * v * (3 - 2 * v)
    }

    private func drawLabel(_ loc: Location, year: Int, alpha: Double) {
        let screen = window?.screen?.frame.height ?? NSScreen.main?.frame.height ?? bounds.height
        let size = max(10, labelSize * bounds.height / screen)
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.5)
        shadow.shadowBlurRadius = size / 4

        let attrs: [NSAttributedString.Key: Any] = [
            .font: Settings.font(labelFont, size: size),
            .foregroundColor: NSColor.white.withAlphaComponent(0.75 * alpha),
            .shadow: shadow,
        ]
        let text = "\(loc.name)  \(loc.firstYear)–\(year)"
        let box = text.size(withAttributes: attrs)
        let margin = size * 1.5
        let left = margin, right = bounds.width - margin - box.width
        let bottom = margin, top = bounds.height - margin - box.height
        let origins = [NSPoint(x: left, y: bottom), NSPoint(x: left, y: top), NSPoint(x: right, y: top), NSPoint(x: right, y: bottom)]
        text.draw(at: origins[corner], withAttributes: attrs)
    }

    override var hasConfigureSheet: Bool { true }

    // One sheet per view, reset to the saved settings each time it opens.
    override var configureSheet: NSWindow? {
        let sheet = options ?? OptionsSheet { [weak self] in
            self?.apply(Settings.current)
        }
        options = sheet
        sheet.reload()
        log.notice("configureSheet requested, preview=\(self.isPreview)")
        return sheet.window
    }
}

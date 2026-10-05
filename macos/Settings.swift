import AppKit
import os
import ScreenSaver

let log = Logger(subsystem: "is.karaman.stripes-saver", category: "saver")

enum DrawStyle: String, CaseIterable {
    case sweep, rise, scatter, fade, drop, flip, blinds, iris, mosaic, random

    // Every style that draws, which is all but random.
    static var animated: [DrawStyle] { allCases.filter { $0 != .random } }

    var title: String {
        switch self {
        case .sweep: "Sweep"
        case .rise: "Rise"
        case .scatter: "Scatter"
        case .fade: "Fade"
        case .drop: "Drop"
        case .flip: "Flip"
        case .blinds: "Blinds"
        case .iris: "Iris"
        case .mosaic: "Mosaic"
        case .random: "Random"
        }
    }
}

// The saver's stored options, shared by the options sheet and every running instance.
struct Settings {
    static let drawInRange = 5.0...60.0
    static let labelSizeRange = 12.0...72.0

    // Label font names that stand for the system fonts; any other name is a font family.
    static let systemMono = "systemMono"
    static let system = "system"

    var selection = ["Global"]
    var style = DrawStyle.sweep
    var exitStyle = DrawStyle.fade

    // Seconds for the build in, and again for the build out.
    var drawIn = 14.0
    var showLabel = true
    var labelFont = Settings.systemMono

    // Label size in points on the full screen. A preview scales it down with its height.
    var labelSize = 24.0

    // A new ScreenSaverDefaults object on every access: an existing one does not see
    // changes saved by the options sheet, which runs in a different process.
    private static func defaults() -> ScreenSaverDefaults? {
        // Fixed rather than the bundle identifier, so settings survive an identifier change.
        ScreenSaverDefaults(forModuleWithName: "is.karaman.stripes-saver")
    }

    static var current: Settings {
        var s = Settings()
        guard let d = defaults() else { return s }
        if let v = d.stringArray(forKey: "locations") { s.selection = v }
        if let v = d.string(forKey: "style").flatMap(DrawStyle.init(rawValue:)) { s.style = v }
        if let v = d.string(forKey: "exitStyle").flatMap(DrawStyle.init(rawValue:)) { s.exitStyle = v }
        if d.double(forKey: "drawIn") > 0 { s.drawIn = d.double(forKey: "drawIn") }
        if let v = d.object(forKey: "showLabel") as? Bool { s.showLabel = v }
        if let v = d.string(forKey: "labelFont") { s.labelFont = v }
        if d.double(forKey: "labelSize") > 0 { s.labelSize = d.double(forKey: "labelSize") }
        return s
    }

    func save() {
        guard let d = Self.defaults() else { return }
        d.set(selection, forKey: "locations")
        d.set(style.rawValue, forKey: "style")
        d.set(exitStyle.rawValue, forKey: "exitStyle")
        d.set(drawIn, forKey: "drawIn")
        d.set(showLabel, forKey: "showLabel")
        d.set(labelFont, forKey: "labelFont")
        d.set(labelSize, forKey: "labelSize")
        d.synchronize()
    }

    // The label font at a given size, in medium weight. A family that is no longer
    // installed falls back to SF Mono.
    static func font(_ name: String, size: CGFloat) -> NSFont {
        switch name {
        case system:
            return .systemFont(ofSize: size, weight: .medium)
        case systemMono:
            return .monospacedSystemFont(ofSize: size, weight: .medium)
        default:
            let fonts = NSFontManager.shared
            return fonts.font(withFamily: name, traits: [], weight: 6, size: size)
                ?? fonts.font(withFamily: name, traits: [], weight: 5, size: size)
                ?? .monospacedSystemFont(ofSize: size, weight: .medium)
        }
    }
}

import AppKit

// Renders one build style as PNG frames: the build in, a short hold, the build out.
// With "in" last, it renders the build in and a short hold only.
// Usage: render <style> <out-dir> [width height fps seconds [in]]
// stripes.json must sit next to the executable, where Bundle(for:) looks for it.

let args = CommandLine.arguments
guard args.count >= 3, let style = DrawStyle(rawValue: args[1]) else {
    print("usage: render <style> <out-dir> [width height fps seconds [in]]")
    exit(1)
}
let out = URL(fileURLWithPath: args[2], isDirectory: true)
let width = args.count > 3 ? Int(args[3])! : 960
let height = args.count > 4 ? Int(args[4])! : 540
let fps = args.count > 5 ? Double(args[5])! : 30
let build = args.count > 6 ? Double(args[6])! : 3
let buildInOnly = args.count > 7 && args[7] == "in"

// The saver holds each picture for 15 s; the clip shows one second of it.
let shownHold = 1.0, hold = 15.0
let gap = 0.4

var now: TimeInterval = 0
StripesView.clock = { now }

var settings = Settings()
settings.selection = ["Global"]
settings.style = style
settings.exitStyle = style
settings.drawIn = build
settings.showLabel = false

let view = StripesView(frame: NSRect(x: 0, y: 0, width: width, height: height), isPreview: true)!
view.apply(settings)

try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
let total = buildInOnly ? build + 1.5 : build + shownHold + build + gap
let frames = Int((total * fps).rounded())
for f in 0..<frames {
    let t = Double(f) / fps
    now = t < build + shownHold ? t : t - shownHold + hold
    let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
    view.cacheDisplay(in: view.bounds, to: rep)
    let name = String(format: "%04d.png", f)
    try rep.representation(using: .png, properties: [:])!.write(to: out.appendingPathComponent(name))
}
print("\(style.rawValue): \(frames) frames")

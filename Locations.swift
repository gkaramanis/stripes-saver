import AppKit

struct Location {
    let name: String
    let region: String
    let firstYear: Int

    // One palette index per year.
    let stripes: [UInt8]
}

private struct StripesFile: Decodable {
    struct Entry: Decodable {
        let region: String
        let country: String
        let place: String
        let firstYear: Int
        let stripes: String
    }

    let palette: [String]
    let locations: [Entry]
}

private let paletteKeys = Array("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")

enum Locations {
    private static let loaded = load()
    static var palette: [NSColor] { loaded.palette }

    // Global first, then alphabetical by name.
    static var all: [Location] { loaded.all }

    private static func load() -> (palette: [NSColor], all: [Location]) {
        guard
            let url = Bundle(for: StripesView.self).url(forResource: "stripes", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let file = try? JSONDecoder().decode(StripesFile.self, from: data)
        else { return ([], []) }

        let list = file.locations.map { e -> Location in
            let name = e.country.isEmpty ? e.region : e.place.isEmpty ? e.country : "\(e.place), \(e.country)"
            let stripes = e.stripes.map { UInt8(paletteKeys.firstIndex(of: $0) ?? 0) }
            return Location(name: name, region: e.region, firstYear: e.firstYear, stripes: stripes)
        }
        let sorted = list.sorted { a, b in
            if (a.name == "Global") != (b.name == "Global") { return a.name == "Global" }
            return a.name.localizedStandardCompare(b.name) == .orderedAscending
        }
        return (file.palette.map(color(hex:)), sorted)
    }

    private static func color(hex: String) -> NSColor {
        let v = UInt32(hex, radix: 16) ?? 0
        return NSColor(
            srgbRed: CGFloat((v >> 16) & 0xff) / 255,
            green: CGFloat((v >> 8) & 0xff) / 255,
            blue: CGFloat(v & 0xff) / 255,
            alpha: 1)
    }

    // The chosen locations in list order, or Global if none of the saved names still exist.
    static func selected(_ names: [String]) -> [Location] {
        let chosen = Set(names)
        let list = all.filter { chosen.contains($0.name) }
        return list.isEmpty ? Array(all.prefix(1)) : list
    }
}

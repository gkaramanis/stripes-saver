import AppKit

// The window behind System Settings' "Options…" button: drawing options and a searchable checkbox list of locations.
final class OptionsSheet: NSObject, NSTableViewDataSource, NSTableViewDelegate, NSSearchFieldDelegate {
    let window: NSWindow

    private let stylePopup = NSPopUpButton()
    private let exitPopup = NSPopUpButton()
    private let speed = NSSlider()
    private let speedValue = NSTextField(labelWithString: "")
    private let showLabel = NSButton(checkboxWithTitle: "Show location and years", target: nil, action: nil)
    private let fontPopup = NSPopUpButton()
    private let size = NSSlider()
    private let sizeValue = NSTextField(labelWithString: "")
    private let search = NSSearchField()
    private let table = NSTableView()
    private let selectedOnly = NSButton(checkboxWithTitle: "Selected only", target: nil, action: nil)
    private let status = NSTextField(labelWithString: "")
    private let done = NSButton(title: "Done", target: nil, action: nil)
    private let cancel = NSButton(title: "Cancel", target: nil, action: nil)
    private let defaults = NSButton(title: "Reset to Defaults…", target: nil, action: nil)
    private let credit = NSTextField(wrappingLabelWithString: "")

    private var chosen: Set<String> = []
    private var rows: [Location] = []
    private let onSave: () -> Void

    init(onSave: @escaping () -> Void) {
        self.onSave = onSave
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.contentView?.wantsLayer = true
        super.init()
        layout()
    }

    // Sets every control from the saved settings, discarding any unsaved changes.
    func reload() {
        show(Settings.current)
    }

    // Resets the drawing options to the shipped defaults after asking. The locations stay as
    // they are, and nothing is saved until Done.
    @objc private func resetToDefaults() {
        let alert = NSAlert()
        alert.messageText = "Reset the options to their defaults?"
        alert.informativeText = "Build in, build out, duration, label, font and size go back to the defaults. The locations stay as they are. Nothing is saved until you click Done."
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")
        alert.beginSheetModal(for: window) { [self] response in
            guard response == .alertFirstButtonReturn else { return }
            var s = Settings()
            s.selection = Locations.all.map(\.name).filter(chosen.contains)
            show(s)
        }
    }

    private func show(_ current: Settings) {
        chosen = Set(current.selection)
        stylePopup.selectItem(at: stylePopup.indexOfItem(withRepresentedObject: current.style.rawValue))
        exitPopup.selectItem(at: exitPopup.indexOfItem(withRepresentedObject: current.exitStyle.rawValue))
        speed.doubleValue = current.drawIn
        speedChanged()
        showLabel.state = current.showLabel ? .on : .off
        let font = fontPopup.indexOfItem(withRepresentedObject: current.labelFont)
        fontPopup.selectItem(at: max(0, font))
        size.doubleValue = current.labelSize
        sizeChanged()
        labelToggled()
        search.stringValue = ""
        selectedOnly.state = .off
        refilter()
        table.scrollRowToVisible(0)
    }

    private func layout() {
        for popup in [stylePopup, exitPopup] {
            for style in DrawStyle.allCases {
                if style == .random { popup.menu?.addItem(.separator()) }
                popup.addItem(withTitle: style.title)
                popup.lastItem?.representedObject = style.rawValue
            }
        }

        speed.minValue = Settings.drawInRange.lowerBound
        speed.maxValue = Settings.drawInRange.upperBound
        speed.target = self
        speed.action = #selector(speedChanged)
        speedValue.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)

        // The system fonts first, then every installed family by name. Items go straight into
        // the menu, since addItem(withTitle:) drops an earlier item with the same title, and
        // Macs with Apple's SF fonts installed also list families named SF Mono and SF Pro.
        let fonts = [("SF Mono", Settings.systemMono), ("SF Pro", Settings.system)]
            + NSFontManager.shared.availableFontFamilies
                .filter { !$0.hasPrefix(".") && $0 != "SF Mono" && $0 != "SF Pro" }
                .map { ($0, $0) }
        for (i, (title, name)) in fonts.enumerated() {
            if i == 2 { fontPopup.menu?.addItem(.separator()) }
            let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            item.representedObject = name
            fontPopup.menu?.addItem(item)
        }
        fontPopup.widthAnchor.constraint(equalToConstant: 220).isActive = true

        size.minValue = Settings.labelSizeRange.lowerBound
        size.maxValue = Settings.labelSizeRange.upperBound
        size.target = self
        size.action = #selector(sizeChanged)
        sizeValue.font = speedValue.font
        showLabel.target = self
        showLabel.action = #selector(labelToggled)

        let drawing = NSGridView(views: [
            [NSTextField(labelWithString: "Build In:"), stylePopup],
            [NSTextField(labelWithString: "Build Out:"), exitPopup],
            [NSTextField(labelWithString: "Duration:"), NSStackView(views: [speed, speedValue])],
            [NSGridCell.emptyContentView, showLabel],
            [NSTextField(labelWithString: "Font:"), fontPopup],
            [NSTextField(labelWithString: "Size:"), NSStackView(views: [size, sizeValue])],
            [NSGridCell.emptyContentView, defaults],
        ])
        drawing.column(at: 0).xPlacement = .trailing

        // The grid spans the sheet, and without a fixed width the label column takes all the spare room.
        drawing.column(at: 0).width = (0..<drawing.numberOfRows)
            .compactMap { drawing.cell(atColumnIndex: 0, rowIndex: $0).contentView?.fittingSize.width }
            .max() ?? 0
        drawing.rowAlignment = .firstBaseline
        drawing.rowSpacing = 8
        speed.widthAnchor.constraint(equalToConstant: 220).isActive = true
        size.widthAnchor.constraint(equalTo: speed.widthAnchor).isActive = true

        let separator = NSBox()
        separator.boxType = .separator

        let locationsTitle = NSTextField(labelWithString: "Locations")
        locationsTitle.font = .boldSystemFont(ofSize: NSFont.systemFontSize)

        search.placeholderString = "Search \(Locations.all.count) locations"
        search.delegate = self

        let column = NSTableColumn(identifier: .init("location"))
        table.addTableColumn(column)
        table.headerView = nil
        table.rowHeight = 22
        table.dataSource = self
        table.delegate = self

        let scroll = NSScrollView()
        scroll.documentView = table
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder

        selectedOnly.target = self
        selectedOnly.action = #selector(refilter)
        status.textColor = .secondaryLabelColor

        defaults.target = self
        defaults.action = #selector(resetToDefaults)
        cancel.target = self
        cancel.action = #selector(cancelled)
        cancel.keyEquivalent = "\u{1b}"
        done.target = self
        done.action = #selector(saved)
        done.keyEquivalent = "\r"

        credit.attributedStringValue = Self.creditText()
        credit.isSelectable = true
        credit.allowsEditingTextAttributes = true

        let buttons = NSStackView(views: [selectedOnly, status, NSView(), cancel, done])
        let stack = NSStackView(views: [drawing, separator, locationsTitle, search, scroll, credit, buttons])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let content = window.contentView!
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            stack.topAnchor.constraint(equalTo: content.topAnchor),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            search.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -32),
            scroll.widthAnchor.constraint(equalTo: search.widthAnchor),
            buttons.widthAnchor.constraint(equalTo: search.widthAnchor),
            separator.widthAnchor.constraint(equalTo: search.widthAnchor),
            credit.widthAnchor.constraint(equalTo: search.widthAnchor),
        ])
        column.width = 420
    }

    // CC BY 4.0 asks for credit, a link to the license and a note of changes.
    private static func creditText() -> NSAttributedString {
        let font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        let text = NSMutableAttributedString(
            string: "Warming stripes by Ed Hawkins, University of Reading, under CC BY 4.0. "
                + "Colors sampled from showyourstripes.info and animated.",
            attributes: [.font: font, .foregroundColor: NSColor.secondaryLabelColor])
        let links = [
            ("showyourstripes.info", "https://showyourstripes.info"),
            ("CC BY 4.0", "https://creativecommons.org/licenses/by/4.0/"),
        ]
        for (label, url) in links {
            text.addAttribute(.link, value: URL(string: url)!, range: (text.string as NSString).range(of: label))
        }
        return text
    }

    @objc private func speedChanged() {
        speed.doubleValue = speed.doubleValue.rounded()
        speedValue.stringValue = "\(Int(speed.doubleValue)) s"
    }

    @objc private func sizeChanged() {
        size.doubleValue = size.doubleValue.rounded()
        sizeValue.stringValue = "\(Int(size.doubleValue)) pt"
    }

    @objc private func labelToggled() {
        let on = showLabel.state == .on
        fontPopup.isEnabled = on
        size.isEnabled = on
    }

    @objc private func refilter() {
        let query = search.stringValue.trimmingCharacters(in: .whitespaces)
        let matches = { (s: String) in
            s.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
        rows = Locations.all.filter { loc in
            (query.isEmpty || matches(loc.name) || matches(loc.region))
                && (selectedOnly.state == .off || chosen.contains(loc.name))
        }
        table.reloadData()
        updateStatus()
    }

    private func updateStatus() {
        status.stringValue = "\(chosen.count) selected"
        done.isEnabled = !chosen.isEmpty
    }

    func controlTextDidChange(_ obj: Notification) {
        refilter()
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        rows.count
    }

    func tableView(_ tableView: NSTableView, viewFor column: NSTableColumn?, row: Int) -> NSView? {
        let id = NSUserInterfaceItemIdentifier("check")
        let box = tableView.makeView(withIdentifier: id, owner: self) as? NSButton
            ?? NSButton(checkboxWithTitle: "", target: self, action: #selector(toggled(_:)))
        box.identifier = id
        box.title = rows[row].name
        box.state = chosen.contains(rows[row].name) ? .on : .off
        return box
    }

    @objc private func toggled(_ sender: NSButton) {
        let row = table.row(for: sender)
        guard row >= 0 else { return }
        let name = rows[row].name
        if sender.state == .on { chosen.insert(name) } else { chosen.remove(name) }
        updateStatus()
    }

    @objc private func saved() {
        let s = Settings(
            selection: Locations.all.map(\.name).filter(chosen.contains),
            style: DrawStyle(rawValue: stylePopup.selectedItem?.representedObject as? String ?? "") ?? .sweep,
            exitStyle: DrawStyle(rawValue: exitPopup.selectedItem?.representedObject as? String ?? "") ?? .fade,
            drawIn: speed.doubleValue,
            showLabel: showLabel.state == .on,
            labelFont: fontPopup.selectedItem?.representedObject as? String ?? Settings.systemMono,
            labelSize: size.doubleValue)
        s.save()
        close()
        onSave()
    }

    @objc private func cancelled() {
        close()
    }

    private func close() {
        if let parent = window.sheetParent {
            parent.endSheet(window)
        } else {
            window.orderOut(nil)
        }
    }
}

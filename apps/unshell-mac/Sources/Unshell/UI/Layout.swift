import AppKit

/// "01  TITLE ───────── 字". Port of the former Electron renderer/ui/SectionHeader.tsx.
func SectionHeader(index: String? = nil, title: String, glyph: String? = nil) -> NSStackView {
    var views: [NSView] = []
    if let index { views.append(UIText.mono(index, size: Theme.TextSize.small, color: Theme.Color.textSecondary)) }
    views.append(Eyebrow(title))
    let rule = Hairline()
    rule.setContentHuggingPriority(.defaultLow, for: .horizontal)
    views.append(rule)
    if let glyph {
        views.append(UIText.label(UIText.attributed(glyph, family: .sans, size: Theme.TextSize.title, color: Theme.Color.text)))
    }
    let stack = NSStackView.horizontal(views, spacing: Theme.Space.s3)
    stack.distribution = .fill
    return stack
}

struct Spec {
    let label: String
    let value: String
    var note: String?
}

/// Label, rule, value rows: the reference's spec sheet. Port of the former Electron renderer/ui/SpecList.tsx.
func SpecList(_ items: [Spec]) -> NSStackView {
    var rows: [NSView] = [Hairline()]
    for item in items {
        var values: [NSView] = [UIText.body(item.value, size: Theme.TextSize.bodyLG, wraps: false)]
        if let note = item.note {
            values.append(UIText.body(note, size: Theme.TextSize.small, color: Theme.Color.textMuted, wraps: false))
        }
        let right = NSStackView.vertical(values, spacing: 0, alignment: .trailing)
        let rule = Hairline()
        rule.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let row = NSStackView.horizontal([Eyebrow(item.label), rule, right], spacing: Theme.Space.s4)
        row.edgeInsets = NSEdgeInsets(top: Theme.Space.s4, left: 0, bottom: Theme.Space.s4, right: 0)
        rows.append(row)
        rows.append(Hairline())
    }
    let stack = NSStackView.vertical(rows, spacing: 0, alignment: .leading)
    for row in rows { row.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true }
    return stack
}

/// Hairline grid of big numbers. Port of the former Electron renderer/ui/StatGrid.tsx.
final class StatGrid: NSView {
    init(_ stats: [(value: String, label: String)]) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.borderWidth = Theme.Size.hairline
        layer?.borderColor = Theme.Color.border.cgColor
        translatesAutoresizingMaskIntoConstraints = false

        var cells: [NSView] = []
        for (index, stat) in stats.enumerated() {
            let value = UIText.label(UIText.attributed(stat.value, family: .sans, size: 28, weight: .light,
                                                       color: Theme.Color.textStrong, leading: 1.2))
            let cell = NSStackView.vertical([value, Eyebrow(stat.label)], spacing: Theme.Space.s1)
            cell.edgeInsets = NSEdgeInsets(top: Theme.Space.s3, left: Theme.Space.s4,
                                           bottom: Theme.Space.s3, right: Theme.Space.s4)
            cells.append(cell)
            if index < stats.count - 1 { cells.append(Hairline(color: Theme.Color.border, vertical: true)) }
        }
        let row = NSStackView.horizontal(cells, spacing: 0, alignment: .height)
        row.distribution = .fill
        addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.topAnchor.constraint(equalTo: topAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        let columns = cells.enumerated().filter { $0.offset % 2 == 0 }.map(\.element)
        for column in columns.dropFirst() {
            column.widthAnchor.constraint(equalTo: columns[0].widthAnchor).isActive = true
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not used") }
}

/// Hairline box with corner brackets, for media, previews and callouts.
/// Port of the former Electron renderer/ui/Frame.tsx.
final class Frame: NSView {
    init(caption: String? = nil, content: NSView) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = Theme.Color.surfaceSunken.cgColor
        layer?.borderWidth = Theme.Size.hairline
        layer?.borderColor = Theme.Color.borderSubtle.cgColor
        translatesAutoresizingMaskIntoConstraints = false

        var views: [NSView] = []
        if let caption { views.append(Eyebrow(caption)) }
        views.append(content)
        let stack = NSStackView.vertical(views, spacing: Theme.Space.s3)
        addSubview(stack)
        let inset = Theme.Space.s6
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -inset),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: inset),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not used") }

    override func draw(_ dirtyRect: NSRect) {
        Theme.Color.textMuted.setStroke()
        let arm: CGFloat = 12, inset: CGFloat = 6.5
        let (minX, minY, maxX, maxY) = (inset, inset, bounds.width - inset, bounds.height - inset)
        let path = NSBezierPath()
        path.lineWidth = Theme.Size.hairline
        for (x, y, dx, dy) in [(minX, minY, 1.0, 1.0), (maxX, minY, -1.0, 1.0),
                               (minX, maxY, 1.0, -1.0), (maxX, maxY, -1.0, -1.0)] {
            path.move(to: NSPoint(x: x + dx * arm, y: y))
            path.line(to: NSPoint(x: x, y: y))
            path.line(to: NSPoint(x: x, y: y + dy * arm))
        }
        path.stroke()
    }
}

struct Feature {
    let glyph: String
    let title: String
    let body: String
}

/// Glyph, title, body columns. Port of the former Electron renderer/ui/FeatureGrid.tsx.
func FeatureGrid(_ items: [Feature]) -> NSStackView {
    var columns: [NSView] = []
    for (index, item) in items.enumerated() {
        let glyph = UIText.label(UIText.attributed(item.glyph, family: .sans, size: Theme.TextSize.title,
                                                   color: Theme.Color.accent))
        let title = UIText.label(UIText.attributed(item.title, family: .sans, size: Theme.TextSize.title,
                                                   weight: Theme.Weight.medium, color: Theme.Color.textStrong,
                                                   leading: Theme.Leading.snug), wraps: true)
        let body = UIText.body(item.body, color: Theme.Color.textMuted)
        let column = NSStackView.vertical([glyph, title, body], spacing: Theme.Space.s2)
        column.setCustomSpacing(Theme.Space.s3, after: glyph)
        column.edgeInsets = NSEdgeInsets(top: Theme.Space.s6, left: index == 0 ? 0 : Theme.Space.s6,
                                         bottom: Theme.Space.s6, right: Theme.Space.s6)
        columns.append(column)
        if index < items.count - 1 { columns.append(Hairline(vertical: true)) }
    }
    let row = NSStackView.horizontal(columns, spacing: 0, alignment: .height)
    let grid = NSStackView.vertical([Hairline(), row], spacing: 0)
    row.widthAnchor.constraint(equalTo: grid.widthAnchor).isActive = true
    let content = columns.enumerated().filter { $0.offset % 2 == 0 }.map(\.element)
    for column in content.dropFirst() { column.widthAnchor.constraint(equalTo: content[0].widthAnchor).isActive = true }
    return grid
}

/// Single-open disclosure list. Port of the former Electron renderer/ui/Accordion.tsx.
final class Accordion: NSView {
    struct Item {
        let id: String
        let title: String
        let content: String
    }

    private var open: String?
    private var panels: [String: NSView] = [:]
    private var markers: [String: NSTextField] = [:]

    init(_ items: [Item], defaultOpen: String? = nil) {
        open = defaultOpen
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        var rows: [NSView] = [Hairline()]
        for item in items {
            let title = UIText.label(UIText.attributed(item.title, family: .sans, size: Theme.TextSize.title,
                                                       weight: Theme.Weight.medium, color: Theme.Color.text,
                                                       leading: Theme.Leading.snug))
            let marker = UIText.label(UIText.attributed("+", family: .sans, size: Theme.TextSize.title,
                                                        color: Theme.Color.textMuted))
            let spacer = NSView()
            spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
            let trigger = ClickableStack(views: [title, spacer, marker]) { [weak self] in self?.toggle(item.id) }
            trigger.edgeInsets = NSEdgeInsets(top: Theme.Space.s5, left: 0, bottom: Theme.Space.s5, right: 0)
            let panel = UIText.body(item.content, color: Theme.Color.textMuted)
            let panelBox = NSStackView.vertical([panel], spacing: 0)
            panelBox.edgeInsets = NSEdgeInsets(top: 0, left: 0, bottom: Theme.Space.s6, right: 0)
            panels[item.id] = panelBox
            markers[item.id] = marker
            let section = NSStackView.vertical([trigger, panelBox], spacing: 0)
            trigger.widthAnchor.constraint(equalTo: section.widthAnchor).isActive = true
            rows.append(section)
            rows.append(Hairline())
        }
        let stack = NSStackView.vertical(rows, spacing: 0)
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        for row in rows { row.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true }
        refresh()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not used") }

    private func toggle(_ id: String) {
        open = open == id ? nil : id
        refresh()
    }

    private func refresh() {
        for (id, panel) in panels {
            panel.isHidden = id != open
            markers[id]?.attributedStringValue = UIText.attributed(
                id == open ? "−" : "+", family: .sans, size: Theme.TextSize.title, color: Theme.Color.textMuted
            )
        }
    }
}

/// A horizontal stack that acts as one button.
final class ClickableStack: NSStackView {
    private let action: () -> Void

    init(views: [NSView], action: @escaping () -> Void) {
        self.action = action
        super.init(frame: .zero)
        orientation = .horizontal
        alignment = .centerY
        translatesAutoresizingMaskIntoConstraints = false
        for view in views { addArrangedSubview(view) }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not used") }

    override func mouseUp(with event: NSEvent) {
        if bounds.contains(convert(event.locationInWindow, from: nil)) { action() }
    }

    override func resetCursorRects() { addCursorRect(bounds, cursor: .pointingHand) }
}

/// Brand, mono nav with an accent underline, actions. Port of the former Electron renderer/ui/TopBar.tsx.
final class TopBar: NSView {
    private var links: [(id: String, label: String, field: NSTextField, underline: NSView)] = []
    private(set) var active: String?
    var onNavigate: ((String) -> Void)?

    init(brand: NSView, nav: [(id: String, label: String)], active: String?, actions: [NSView]) {
        self.active = active
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = Theme.Color.canvas.cgColor
        translatesAutoresizingMaskIntoConstraints = false

        var navViews: [NSView] = []
        for item in nav {
            let field = Eyebrow(item.label)
            let underline = Hairline(color: .clear)
            let column = NSStackView.vertical([field, underline], spacing: Theme.Space.s1)
            underline.widthAnchor.constraint(equalTo: column.widthAnchor).isActive = true
            let button = ClickableStack(views: [column]) { [weak self] in self?.navigate(item.id) }
            navViews.append(button)
            links.append((item.id, item.label, field, underline))
        }
        let navStack = NSStackView.horizontal(navViews, spacing: Theme.Space.s6)
        let actionStack = NSStackView.horizontal(actions, spacing: Theme.Space.s2)
        let bottom = Hairline()
        for view in [brand, navStack, actionStack, bottom] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 56),
            brand.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Theme.Space.s6),
            brand.centerYAnchor.constraint(equalTo: centerYAnchor),
            navStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            navStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            actionStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Theme.Space.s6),
            actionStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            bottom.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottom.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottom.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        refresh()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not used") }

    private func navigate(_ id: String) {
        active = id
        refresh()
        onNavigate?(id)
    }

    private func refresh() {
        for link in links {
            let isActive = link.id == active
            link.field.attributedStringValue = UIText.attributed(
                link.label, family: .mono, size: Theme.TextSize.label, weight: Theme.Weight.medium,
                color: isActive ? Theme.Color.textStrong : Theme.Color.textSecondary,
                tracking: Theme.Tracking.label, uppercase: true
            )
            link.underline.layer?.backgroundColor = (isActive ? Theme.Color.accent : .clear).cgColor
        }
    }
}

/// Film grain over a canvas: a tiled noise layer at `Theme.Grain.opacity` that
/// ignores the mouse. Add it last so it sits on top.
final class GrainOverlay: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor(patternImage: Theme.Grain.tile).cgColor
        layer?.opacity = Theme.Grain.opacity
        translatesAutoresizingMaskIntoConstraints = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not used") }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

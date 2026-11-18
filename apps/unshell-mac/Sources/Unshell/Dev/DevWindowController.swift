#if DEBUG
import AppKit

/// The development-only area: a sidebar of registered dev views and the active
/// view. Port of the former Electron renderer/dev/DevArea.tsx and DevTools.tsx. Escape closes it.
final class DevWindowController: NSWindowController, NSWindowDelegate {
    static let shared = DevWindowController()

    private let nav = NSStackView.vertical([], spacing: 0)
    private let host = NSView()
    private var activeId: String?
    private var navLabels: [String: NSTextField] = [:]

    private init() {
        let window = DevWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1320, height: 880),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        window.title = "Development only"
        window.titlebarAppearsTransparent = true
        window.appearance = NSAppearance(named: .darkAqua)
        window.backgroundColor = Theme.Color.canvas
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("UnshellDev")
        super.init(window: window)
        window.delegate = self
        build()
        show(DevViews.all.first?.id ?? "")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not used") }

    func show(_ id: String) {
        guard let entry = DevViews.all.first(where: { $0.id == id }) else { return }
        activeId = id
        for (key, label) in navLabels {
            label.attributedStringValue = navTitle(DevViews.all.first { $0.id == key }!.label, active: key == id)
        }
        host.subviews.forEach { $0.removeFromSuperview() }

        let view = entry.make()
        let container: NSView
        if entry.scrolls {
            let scroll = NSScrollView()
            scroll.drawsBackground = false
            scroll.hasVerticalScroller = true
            scroll.documentView = view
            view.widthAnchor.constraint(equalTo: scroll.contentView.widthAnchor).isActive = true
            view.topAnchor.constraint(equalTo: scroll.contentView.topAnchor).isActive = true
            container = scroll
        } else {
            container = view
        }
        let canvas = DevContainer(content: container)
        canvas.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(canvas)
        NSLayoutConstraint.activate([
            canvas.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            canvas.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            canvas.topAnchor.constraint(equalTo: host.topAnchor),
            canvas.bottomAnchor.constraint(equalTo: host.bottomAnchor),
        ])
        window?.title = "Development only · \(entry.label)"
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }

    private func navTitle(_ label: String, active: Bool) -> NSAttributedString {
        UIText.attributed(label, family: .sans, size: Theme.TextSize.body,
                          color: active ? Theme.Color.textStrong : Theme.Color.textSecondary)
    }

    private func build() {
        guard let root = window?.contentView else { return }
        root.wantsLayer = true
        root.layer?.backgroundColor = Theme.Color.canvas.cgColor

        let sidebar = NSView()
        sidebar.wantsLayer = true
        sidebar.layer?.backgroundColor = Theme.Color.surfaceSunken.cgColor
        sidebar.translatesAutoresizingMaskIntoConstraints = false

        nav.addArrangedSubview(Eyebrow("Development only"))
        nav.setCustomSpacing(Theme.Space.s4, after: nav.arrangedSubviews[0])
        for entry in DevViews.all {
            let label = UIText.label(navTitle(entry.label, active: false))
            navLabels[entry.id] = label
            let item = ClickableStack(views: [label]) { [weak self] in self?.show(entry.id) }
            item.edgeInsets = NSEdgeInsets(top: Theme.Space.s2, left: 0, bottom: Theme.Space.s2, right: 0)
            nav.addArrangedSubview(item)
        }
        nav.edgeInsets = NSEdgeInsets(top: 48, left: Theme.Space.s5, bottom: Theme.Space.s5, right: Theme.Space.s5)
        sidebar.addSubview(nav)

        let rule = Hairline(color: Theme.Color.borderSubtle, vertical: true)
        host.translatesAutoresizingMaskIntoConstraints = false
        for view in [sidebar, rule, host] { root.addSubview(view) }
        NSLayoutConstraint.activate([
            sidebar.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            sidebar.topAnchor.constraint(equalTo: root.topAnchor),
            sidebar.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            sidebar.widthAnchor.constraint(equalToConstant: 220),
            nav.leadingAnchor.constraint(equalTo: sidebar.leadingAnchor),
            nav.trailingAnchor.constraint(equalTo: sidebar.trailingAnchor),
            nav.topAnchor.constraint(equalTo: sidebar.topAnchor),
            rule.leadingAnchor.constraint(equalTo: sidebar.trailingAnchor),
            rule.topAnchor.constraint(equalTo: root.topAnchor),
            rule.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            host.leadingAnchor.constraint(equalTo: rule.trailingAnchor),
            host.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            host.topAnchor.constraint(equalTo: root.topAnchor, constant: 28),
            host.bottomAnchor.constraint(equalTo: root.bottomAnchor),
        ])
    }

    @objc func showDevView(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        show(id)
    }
}

/// Escape closes the dev area, as in the Electron renderer.
private final class DevWindow: NSWindow {
    override func cancelOperation(_ sender: Any?) { performClose(sender) }
}

/// The Dev menu: one item per registered view. Only exists in Debug builds.
enum DevMenu {
    static func item() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: "Dev")
        for (index, entry) in DevViews.all.enumerated() {
            let viewItem = NSMenuItem(title: entry.label, action: #selector(DevWindowController.showDevView(_:)),
                                      keyEquivalent: index < 9 ? "\(index + 1)" : "")
            viewItem.keyEquivalentModifierMask = [.command, .option]
            viewItem.representedObject = entry.id
            viewItem.target = DevWindowController.shared
            menu.addItem(viewItem)
        }
        item.submenu = menu
        return item
    }
}
#endif

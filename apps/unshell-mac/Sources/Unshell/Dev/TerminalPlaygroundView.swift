#if DEBUG
import AppKit
import GhosttyKit

/// Terminal tabs playground: open, switch and close terminals, with renderer
/// and grid-size badges. Port of renderer/dev/views/TerminalView.tsx.
final class TerminalPlaygroundView: NSView {
    private struct Tab {
        let view: TerminalSurfaceView
    }

    private var tabs: [Tab] = []
    private var activeIndex: Int?
    private let tabStrip = NSStackView.horizontal([], spacing: Theme.Space.s1)
    private let meta = NSStackView.horizontal([], spacing: Theme.Space.s2)
    private let body = NSView()
    private var refreshTimer: Timer?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        translatesAutoresizingMaskIntoConstraints = false

        let toolbar = NSView()
        toolbar.wantsLayer = true
        toolbar.layer?.backgroundColor = Theme.Color.canvas.cgColor
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        let rule = Hairline()
        body.wantsLayer = true
        body.layer?.backgroundColor = Theme.Color.surface.cgColor
        body.translatesAutoresizingMaskIntoConstraints = false
        for view in [tabStrip, meta] { toolbar.addSubview(view) }
        for view in [toolbar, rule, body] { addSubview(view) }
        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
            toolbar.topAnchor.constraint(equalTo: topAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: Theme.Size.controlLG),
            tabStrip.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor, constant: Theme.Space.s4),
            tabStrip.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
            meta.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor, constant: -Theme.Space.s4),
            meta.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
            rule.leadingAnchor.constraint(equalTo: leadingAnchor),
            rule.trailingAnchor.constraint(equalTo: trailingAnchor),
            rule.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            body.leadingAnchor.constraint(equalTo: leadingAnchor),
            body.trailingAnchor.constraint(equalTo: trailingAnchor),
            body.topAnchor.constraint(equalTo: rule.bottomAnchor),
            body.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        addTab()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.refresh() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not used") }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        // Leaving the dev area frees every playground terminal.
        if newWindow == nil {
            refreshTimer?.invalidate()
            for tab in tabs { tab.view.removeFromSuperview(); tab.view.destroy() }
            tabs.removeAll()
        }
    }

    private var runtime: GhosttyRuntime? { (NSApp.delegate as? AppDelegate)?.runtime }

    private func addTab() {
        guard let runtime else { return }
        let view = TerminalSurfaceView(runtime: runtime)
        view.onRestartRequested = { [weak self] old in self?.replace(old) }
        place(view)
        tabs.append(Tab(view: view))
        select(tabs.count - 1)
    }

    private func place(_ view: TerminalSurfaceView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        body.addSubview(view)
        let inset = Theme.Space.s3
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: body.leadingAnchor, constant: inset),
            view.trailingAnchor.constraint(equalTo: body.trailingAnchor, constant: -inset),
            view.topAnchor.constraint(equalTo: body.topAnchor, constant: inset),
            view.bottomAnchor.constraint(equalTo: body.bottomAnchor, constant: -inset),
        ])
    }

    private func replace(_ old: TerminalSurfaceView) {
        guard let index = tabs.firstIndex(where: { $0.view === old }), let runtime else { return }
        let view = TerminalSurfaceView(runtime: runtime)
        view.onRestartRequested = { [weak self] old in self?.replace(old) }
        place(view)
        tabs[index] = Tab(view: view)
        old.removeFromSuperview()
        old.destroy()
        select(index)
    }

    private func close(_ index: Int) {
        guard tabs.indices.contains(index) else { return }
        let tab = tabs.remove(at: index)
        tab.view.removeFromSuperview()
        tab.view.destroy()
        activeIndex = nil
        if !tabs.isEmpty { select(min(index, tabs.count - 1)) } else { refresh() }
    }

    private func select(_ index: Int) {
        for (offset, tab) in tabs.enumerated() { tab.view.setVisibleToUser(offset == index) }
        activeIndex = index
        window?.makeFirstResponder(tabs[index].view)
        refresh()
    }

    private func refresh() {
        tabStrip.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, tab) in tabs.enumerated() {
            let name = tab.view.hasExited ? "\(tab.view.title) · exited" : tab.view.title
            let button = UButton(name, variant: index == activeIndex ? .secondary : .ghost, size: .sm) { [weak self] in
                self?.select(index)
            }
            let close = UButton("×", variant: .ghost, size: .sm) { [weak self] in self?.close(index) }
            tabStrip.addArrangedSubview(NSStackView.horizontal([button, close], spacing: 0))
        }
        tabStrip.addArrangedSubview(UButton("+ New", variant: .ghost, size: .sm) { [weak self] in self?.addTab() })

        meta.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if let index = activeIndex, tabs.indices.contains(index), let surface = tabs[index].view.surface {
            let size = ghostty_surface_size(surface)
            meta.addArrangedSubview(Badge("metal", tone: .success, dot: true))
            meta.addArrangedSubview(Badge("\(size.columns)×\(size.rows)"))
        } else if tabs.isEmpty {
            meta.addArrangedSubview(UButton("Open a terminal", variant: .primary, size: .sm) { [weak self] in self?.addTab() })
        }
    }
}
#endif

import AppKit

/// The default window: a quiet home screen with a title and two actions. Dev
/// (Debug builds only) opens the development area: Design system, Code viewer,
/// Terminal playground. New Terminal (also ⌘T) opens the terminal window.
final class HomeWindowController: NSWindowController {
    private let onNewTerminal: () -> Void

    init(onNewTerminal: @escaping () -> Void) {
        self.onNewTerminal = onNewTerminal
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1280, height: 860),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Unshell"
        window.titlebarAppearsTransparent = true
        window.backgroundColor = Theme.Color.canvas
        window.appearance = NSAppearance(named: .darkAqua)
        window.setFrameAutosaveName("UnshellHome")
        window.center()
        super.init(window: window)
        build()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not used") }

    private func build() {
        guard let root = window?.contentView else { return }
        root.wantsLayer = true
        root.layer?.backgroundColor = Theme.Color.canvas.cgColor

        let eyebrow = Eyebrow("Workspaces · Agents · Terminals")
        let title = Display("Unshell", size: .lg)
        let lede = UIText.body("A development environment for people and agents.", size: Theme.TextSize.bodyLG,
                               color: Theme.Color.textSecondary, wraps: false)

        var actions: [NSView] = []
        #if DEBUG
        actions.append(UButton("Dev", variant: .primary) {
            DevWindowController.shared.show(DevViews.all.first?.id ?? "")
        })
        #endif
        let newTerminal = UButton("New Terminal", variant: actions.isEmpty ? .primary : .secondary) { [weak self] in
            self?.onNewTerminal()
        }
        actions.append(newTerminal)
        let buttons = NSStackView.horizontal(actions, spacing: Theme.Space.s3)

        let hint = UIText.mono("⌘T  NEW TERMINAL", size: Theme.TextSize.label, color: Theme.Color.textFaint)
        let stack = NSStackView.vertical([eyebrow, title, lede, buttons, hint], spacing: Theme.Space.s4, alignment: .leading)
        stack.setCustomSpacing(Theme.Space.s8, after: lede)
        root.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: Theme.Space.s16),
            stack.centerYAnchor.constraint(equalTo: root.centerYAnchor),
        ])

        let grain = GrainOverlay()
        root.addSubview(grain)
        NSLayoutConstraint.activate([
            grain.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            grain.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            grain.topAnchor.constraint(equalTo: root.topAnchor),
            grain.bottomAnchor.constraint(equalTo: root.bottomAnchor),
        ])
    }
}

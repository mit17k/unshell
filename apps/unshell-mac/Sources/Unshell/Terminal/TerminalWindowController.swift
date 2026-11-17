import AppKit
import GhosttyKit

/// One window: a sidebar listing every terminal and a content area showing the
/// selected one. Every terminal stays alive; only the selected surface is
/// visible, the rest are occluded so their renderers idle.
final class TerminalWindowController: NSWindowController, GhosttyRuntimeDelegate {
    private let runtime: GhosttyRuntime
    private var terminals: [TerminalSurfaceView] = []
    private var selectedIndex: Int?

    private let sidebar = TerminalSidebar()
    private let content = NSView()
    private let statusLabel = NSTextField(labelWithString: "")
    /// Shown over the selected terminal once its process has exited.
    private let exitBanner = NSTextField(labelWithString: "")
    private var statusTimer: Timer?
    private let usage = ProcessUsage()

    /// Agents (Claude Code especially) animate the terminal title many times a
    /// second. Title changes are batched and the sidebar refreshed at most ~5x/s.
    private var pendingTitleRows = IndexSet()
    private var titleFlushScheduled = false

    init(runtime: GhosttyRuntime) {
        self.runtime = runtime
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1280, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Unshell"
        window.titlebarAppearsTransparent = true
        window.backgroundColor = Theme.Color.bg
        window.appearance = NSAppearance(named: .darkAqua)
        window.setFrameAutosaveName("UnshellMain")
        window.center()
        super.init(window: window)
        buildLayout()
        startStatusTimer()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not used") }

    private func buildLayout() {
        guard let root = window?.contentView else { return }

        sidebar.onSelect = { [weak self] index in self?.select(index) }
        sidebar.translatesAutoresizingMaskIntoConstraints = false

        content.wantsLayer = true
        content.layer?.backgroundColor = Theme.Color.bg.cgColor
        content.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.font = Theme.Font.monoLabel
        statusLabel.textColor = Theme.Color.fgMuted
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        let rule = NSBox()
        rule.boxType = .custom
        rule.borderWidth = 0
        rule.fillColor = Theme.Color.rule
        rule.translatesAutoresizingMaskIntoConstraints = false

        root.addSubview(sidebar)
        root.addSubview(rule)
        root.addSubview(content)
        root.addSubview(statusLabel)

        exitBanner.font = Theme.Font.monoLabel
        exitBanner.textColor = Theme.Color.fgStrong
        exitBanner.drawsBackground = true
        exitBanner.backgroundColor = Theme.Color.surfaceRaised
        exitBanner.alignment = .center
        exitBanner.isHidden = true
        exitBanner.translatesAutoresizingMaskIntoConstraints = false
        // Sibling above the surfaces, not a subview of a Metal-hosting view.
        root.addSubview(exitBanner, positioned: .above, relativeTo: content)

        NSLayoutConstraint.activate([
            sidebar.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            sidebar.topAnchor.constraint(equalTo: root.topAnchor, constant: 28),
            sidebar.bottomAnchor.constraint(equalTo: statusLabel.topAnchor, constant: -6),
            sidebar.widthAnchor.constraint(equalToConstant: 220),

            rule.leadingAnchor.constraint(equalTo: sidebar.trailingAnchor),
            rule.topAnchor.constraint(equalTo: root.topAnchor),
            rule.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            rule.widthAnchor.constraint(equalToConstant: 1),

            content.leadingAnchor.constraint(equalTo: rule.trailingAnchor),
            content.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            content.topAnchor.constraint(equalTo: root.topAnchor, constant: 28),
            content.bottomAnchor.constraint(equalTo: root.bottomAnchor),

            statusLabel.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 12),
            statusLabel.widthAnchor.constraint(equalToConstant: 200),
            statusLabel.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -8),

            exitBanner.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            exitBanner.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            exitBanner.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            exitBanner.heightAnchor.constraint(equalToConstant: 28),
        ])
    }

    // MARK: Terminal lifecycle

    @discardableResult
    func newTerminal(workingDirectory: String? = nil, command: String? = nil, select shouldSelect: Bool = true) -> TerminalSurfaceView {
        let view = makeTerminalView(workingDirectory: workingDirectory, command: command)
        terminals.append(view)
        sidebar.terminals = terminals
        if shouldSelect {
            select(terminals.count - 1)
        } else {
            view.setVisibleToUser(false)
        }
        return view
    }

    private func makeTerminalView(workingDirectory: String?, command: String?) -> TerminalSurfaceView {
        let view = TerminalSurfaceView(runtime: runtime, workingDirectory: workingDirectory, command: command)
        view.onRestartRequested = { [weak self] view in self?.restart(view) }
        view.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            view.topAnchor.constraint(equalTo: content.topAnchor),
            view.bottomAnchor.constraint(equalTo: content.bottomAnchor),
        ])
        return view
    }

    /// Replaces an exited terminal with a fresh one in the same row, same
    /// working directory and command.
    private func restart(_ old: TerminalSurfaceView) {
        guard let index = terminals.firstIndex(where: { $0 === old }) else { return }
        GhosttyRuntime.log.info("restart terminal row=\(index + 1, privacy: .public)")
        let view = makeTerminalView(workingDirectory: old.workingDirectory, command: old.command)
        terminals[index] = view
        old.removeFromSuperview()
        old.destroy()
        sidebar.terminals = terminals
        if selectedIndex == index {
            selectedIndex = nil
            select(index)
        } else {
            view.setVisibleToUser(false)
        }
    }

    func openStressTerminals(count: Int, command: String?) {
        // Default: a steady flood of mixed-width output, roughly what a busy agent
        // log looks like. Each terminal runs its own copy.
        let flood = command ?? "/bin/bash -lc 'while :; do ls -la /usr/bin; printf \"\\e[3%dm▌ agent %s ✓ \\e[0m\\n\" $((RANDOM%7+1)) $RANDOM; done'"
        for index in 0..<count {
            newTerminal(command: flood, select: index == 0)
        }
    }

    private func select(_ index: Int) {
        guard terminals.indices.contains(index) else { return }
        if let previous = selectedIndex, previous != index, terminals.indices.contains(previous) {
            terminals[previous].setVisibleToUser(false)
        }
        selectedIndex = index
        let view = terminals[index]
        view.setVisibleToUser(true)
        window?.makeFirstResponder(view)
        window?.title = view.title
        sidebar.select(index)
        updateExitBanner()
    }

    private func updateExitBanner() {
        guard let index = selectedIndex, terminals.indices.contains(index),
              let status = terminals[index].exitStatus
        else {
            exitBanner.isHidden = true
            return
        }
        exitBanner.stringValue = "PROCESS EXITED (CODE \(status.code)) · RETURN OR ⌘R TO RESTART"
        exitBanner.isHidden = false
    }

    private func close(_ view: TerminalSurfaceView) {
        guard let index = terminals.firstIndex(where: { $0 === view }) else { return }
        terminals.remove(at: index)
        view.removeFromSuperview()
        view.destroy()
        sidebar.terminals = terminals

        if terminals.isEmpty {
            selectedIndex = nil
            window?.close()
            return
        }
        selectedIndex = nil
        select(min(index, terminals.count - 1))
    }

    // MARK: Menu actions

    @objc func newTerminalAction(_ sender: Any?) {
        let cwd = selectedIndex.flatMap { terminals[$0].workingDirectory }
        newTerminal(workingDirectory: cwd)
    }

    @objc func closeTerminalAction(_ sender: Any?) {
        guard let index = selectedIndex, let surface = terminals[index].surface else { return }
        // Goes through libghostty so it can confirm when a process is still running.
        ghostty_surface_request_close(surface)
    }

    @objc func restartTerminalAction(_ sender: Any?) {
        // Only exited terminals restart; ⌘R must never kill a live shell.
        guard let index = selectedIndex, terminals.indices.contains(index), terminals[index].hasExited else {
            NSSound.beep()
            return
        }
        restart(terminals[index])
    }

    @objc func nextTerminalAction(_ sender: Any?) { step(1) }
    @objc func previousTerminalAction(_ sender: Any?) { step(-1) }

    private func step(_ delta: Int) {
        guard !terminals.isEmpty else { return }
        let current = selectedIndex ?? 0
        select((current + delta + terminals.count) % terminals.count)
    }

    // MARK: GhosttyRuntimeDelegate

    func ghosttyNewTerminal(from surface: TerminalSurfaceView?) {
        newTerminal(workingDirectory: surface?.workingDirectory)
    }

    func ghosttyCloseTerminal(_ surface: TerminalSurfaceView, reason: String) {
        let row = terminals.firstIndex(where: { $0 === surface }).map { $0 + 1 } ?? 0
        GhosttyRuntime.log.info("close terminal row=\(row, privacy: .public) reason=\(reason, privacy: .public)")
        close(surface)
    }

    func ghosttyChildExited(_ surface: TerminalSurfaceView, exitCode: UInt32, runtimeMs: UInt64) {
        surface.markExited(code: exitCode, runtimeMs: runtimeMs)
        guard let index = terminals.firstIndex(where: { $0 === surface }) else { return }
        sidebar.reloadRows(IndexSet(integer: index))
        if index == selectedIndex { updateExitBanner() }
    }

    func ghosttyGotoTerminal(_ target: ghostty_action_goto_tab_e) {
        switch target {
        case GHOSTTY_GOTO_TAB_PREVIOUS: step(-1)
        case GHOSTTY_GOTO_TAB_NEXT: step(1)
        case GHOSTTY_GOTO_TAB_LAST: select(terminals.count - 1)
        default:
            // Positive values are 1-based indices (cmd+1...cmd+9).
            let index = Int(target.rawValue) - 1
            select(index)
        }
    }

    func ghosttyTitleChanged(_ surface: TerminalSurfaceView, title: String) {
        surface.title = title
        guard let index = terminals.firstIndex(where: { $0 === surface }) else { return }
        pendingTitleRows.insert(index)
        guard !titleFlushScheduled else { return }
        titleFlushScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self else { return }
            self.titleFlushScheduled = false
            self.sidebar.reloadRows(self.pendingTitleRows)
            self.pendingTitleRows.removeAll()
            if let selected = self.selectedIndex, self.terminals.indices.contains(selected) {
                self.window?.title = self.terminals[selected].title
            }
        }
    }

    func ghosttyWorkingDirectoryChanged(_ surface: TerminalSurfaceView, path: String) {
        surface.workingDirectory = path
    }

    // MARK: Status

    private func startStatusTimer() {
        statusTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            let sample = self.usage.sample()
            self.statusLabel.stringValue = String(
                format: "%d TERMINALS · %.0f%% CPU · %.0f MB",
                self.terminals.count, sample.cpuPercent, sample.residentMB
            )
        }
    }
}

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) var runtime: GhosttyRuntime?
    private var windowController: TerminalWindowController?
    private var home: HomeWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = MainMenu.build()

        let runtime: GhosttyRuntime
        do {
            runtime = try GhosttyRuntime()
        } catch {
            let alert = NSAlert()
            alert.messageText = "Unshell could not start the terminal engine"
            alert.informativeText = "\(error)"
            alert.runModal()
            NSApp.terminate(nil)
            return
        }
        self.runtime = runtime

        // The terminal window exists from launch (it receives libghostty's
        // events) but is shown only when a terminal is opened.
        let controller = TerminalWindowController(runtime: runtime)
        runtime.delegate = controller
        windowController = controller
        // With no terminals left, go back to the home screen rather than quit.
        controller.onAllTerminalsClosed = { [weak self] in self?.showHome() }

        // UNSHELL_STRESS=<n> opens n terminals running UNSHELL_STRESS_CMD (or a
        // default output flood) to measure the cost of many live surfaces.
        let env = ProcessInfo.processInfo.environment
        if let raw = env["UNSHELL_STRESS"], let count = Int(raw), count > 0 {
            controller.showWindow(nil)
            controller.openStressTerminals(count: count, command: env["UNSHELL_STRESS_CMD"])
        } else {
            showHome()
        }

        NSApp.activate(ignoringOtherApps: true)

        #if DEBUG
        // UNSHELL_DEV_VIEW=<id> opens the dev area on that view at launch.
        if let devView = env["UNSHELL_DEV_VIEW"] {
            DevWindowController.shared.show(devView)
        }
        CodeViewerBenchmark.runIfRequested()
        #endif
    }

    private func showHome() {
        let home = self.home ?? HomeWindowController(onNewTerminal: { [weak self] in self?.newTerminalAction(nil) })
        self.home = home
        home.showWindow(nil)
    }

    /// Shell › New Terminal (⌘T) when no terminal window is key, and the home
    /// screen's New Terminal button: show the terminal window, open a terminal.
    @objc func newTerminalAction(_ sender: Any?) {
        guard let controller = windowController else { return }
        controller.showWindow(nil)
        controller.newTerminal()
        home?.window?.orderOut(nil)
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        runtime?.setFocus(true)
    }

    func applicationDidResignActive(_ notification: Notification) {
        runtime?.setFocus(false)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

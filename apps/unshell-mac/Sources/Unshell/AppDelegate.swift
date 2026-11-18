import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) var runtime: GhosttyRuntime?
    private var windowController: TerminalWindowController?

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

        let controller = TerminalWindowController(runtime: runtime)
        runtime.delegate = controller
        windowController = controller
        controller.showWindow(nil)

        // UNSHELL_STRESS=<n> opens n terminals running UNSHELL_STRESS_CMD (or a
        // default output flood) to measure the cost of many live surfaces.
        let env = ProcessInfo.processInfo.environment
        if let raw = env["UNSHELL_STRESS"], let count = Int(raw), count > 0 {
            controller.openStressTerminals(count: count, command: env["UNSHELL_STRESS_CMD"])
        } else {
            controller.newTerminal()
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

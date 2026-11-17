import AppKit

/// Programmatic main menu (no nib). Terminal actions target the first responder,
/// so they reach the focused `TerminalSurfaceView` or the window controller.
enum MainMenu {
    static func build() -> NSMenu {
        let main = NSMenu()

        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Unshell", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide Unshell", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "Quit Unshell", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        main.addItem(appItem)

        let shellItem = NSMenuItem()
        let shellMenu = NSMenu(title: "Shell")
        shellMenu.addItem(withTitle: "New Terminal", action: #selector(TerminalWindowController.newTerminalAction(_:)), keyEquivalent: "t")
        shellMenu.addItem(withTitle: "Close Terminal", action: #selector(TerminalWindowController.closeTerminalAction(_:)), keyEquivalent: "w")
        shellMenu.addItem(.separator())
        shellMenu.addItem(withTitle: "Next Terminal", action: #selector(TerminalWindowController.nextTerminalAction(_:)), keyEquivalent: "}")
        shellMenu.addItem(withTitle: "Previous Terminal", action: #selector(TerminalWindowController.previousTerminalAction(_:)), keyEquivalent: "{")
        shellItem.submenu = shellMenu
        main.addItem(shellItem)

        let editItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Copy", action: #selector(TerminalSurfaceView.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(TerminalSurfaceView.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSResponder.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = editMenu
        main.addItem(editItem)

        let windowItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowItem.submenu = windowMenu
        main.addItem(windowItem)
        NSApp.windowsMenu = windowMenu

        return main
    }
}

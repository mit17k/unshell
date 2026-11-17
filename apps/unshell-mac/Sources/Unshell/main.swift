import AppKit
import GhosttyKit

// libghostty must be initialised once, before any config/app/surface call.
if ghostty_init(UInt(CommandLine.argc), CommandLine.unsafeArgv) != GHOSTTY_SUCCESS {
    FileHandle.standardError.write("ghostty_init failed\n".data(using: .utf8)!)
    exit(1)
}

let application = NSApplication.shared
let appDelegate = AppDelegate()
application.delegate = appDelegate
application.setActivationPolicy(.regular)
application.run()

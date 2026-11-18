import AppKit
import GhosttyKit

// libghostty must be initialised once, before any config/app/surface call.
if ghostty_init(UInt(CommandLine.argc), CommandLine.unsafeArgv) != GHOSTTY_SUCCESS {
    FileHandle.standardError.write("ghostty_init failed\n".data(using: .utf8)!)
    exit(1)
}

let application = NSApplication.shared

// SIGTERM (e.g. `just mac-run` replacing a running build) quits like ⌘Q, so
// the app delegate and libghostty shut down normally.
signal(SIGTERM, SIG_IGN)
let terminationSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
terminationSource.setEventHandler { NSApp.terminate(nil) }
terminationSource.resume()

#if DEBUG
// Scripted snapshot of a dev view; exits when done.
_ = application
if DevSnapshot.runIfRequested() { exit(0) }
#endif

let appDelegate = AppDelegate()
application.delegate = appDelegate
application.setActivationPolicy(.regular)
application.run()

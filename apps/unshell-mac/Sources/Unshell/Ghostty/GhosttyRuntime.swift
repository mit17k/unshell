import AppKit
import GhosttyKit
import os

/// Events libghostty raises that the window layer has to act on.
protocol GhosttyRuntimeDelegate: AnyObject {
    func ghosttyNewTerminal(from surface: TerminalSurfaceView?)
    func ghosttyCloseTerminal(_ surface: TerminalSurfaceView, processAlive: Bool)
    func ghosttyGotoTerminal(_ target: ghostty_action_goto_tab_e)
    func ghosttyTitleChanged(_ surface: TerminalSurfaceView, title: String)
    func ghosttyWorkingDirectoryChanged(_ surface: TerminalSurfaceView, path: String)
}

enum GhosttyRuntimeError: Error, CustomStringConvertible {
    case configAllocationFailed
    case appCreationFailed

    var description: String {
        switch self {
        case .configAllocationFailed: return "ghostty_config_new returned null"
        case .appCreationFailed: return "ghostty_app_new returned null"
        }
    }
}

/// Owns the single `ghostty_app_t` for the process. Every terminal is a surface
/// of this one app, so fonts, config and the shared glyph atlas are not duplicated
/// per terminal.
final class GhosttyRuntime {
    static let log = Logger(subsystem: "dev.unshell.mac", category: "ghostty")

    private(set) var app: ghostty_app_t!
    private(set) var config: ghostty_config_t
    weak var delegate: GhosttyRuntimeDelegate?

    /// Coalesces wakeups: libghostty can call wakeup from any thread, many times
    /// per frame when 50 terminals stream output. One pending tick is enough.
    private let tickLock = OSAllocatedUnfairLock(initialState: false)

    init() throws {
        guard let config = ghostty_config_new() else { throw GhosttyRuntimeError.configAllocationFailed }
        self.config = config
        Self.loadConfig(config)

        var runtimeConfig = ghostty_runtime_config_s(
            userdata: nil,
            supports_selection_clipboard: false,
            wakeup_cb: { userdata in GhosttyRuntime.wakeup(userdata) },
            action_cb: { app, target, action in GhosttyRuntime.action(app, target: target, action: action) },
            read_clipboard_cb: { userdata, location, state, mimes, mimesLen, list in
                GhosttyRuntime.readClipboard(userdata, location: location, state: state, mimes: mimes, mimesLen: mimesLen, list: list)
            },
            confirm_read_clipboard_cb: { userdata, _, state, _ in
                // Unshell's config disables paste protection and OSC 52 reads, so
                // libghostty should never ask. If it does, refuse rather than guess.
                guard let view = TerminalSurfaceView.from(userdata: userdata), let surface = view.surface else { return }
                ghostty_surface_deny_clipboard_request(surface, state)
            },
            write_clipboard_cb: { userdata, location, content, len, confirm in
                GhosttyRuntime.writeClipboard(userdata, location: location, content: content, len: len, confirm: confirm)
            },
            close_surface_cb: { userdata, processAlive in
                guard let view = TerminalSurfaceView.from(userdata: userdata) else { return }
                DispatchQueue.main.async {
                    view.runtime?.delegate?.ghosttyCloseTerminal(view, processAlive: processAlive)
                }
            }
        )
        runtimeConfig.userdata = Unmanaged.passUnretained(self).toOpaque()

        guard let app = ghostty_app_new(&runtimeConfig, config) else {
            ghostty_config_free(config)
            throw GhosttyRuntimeError.appCreationFailed
        }
        self.app = app
        ghostty_app_set_focus(app, NSApp.isActive)
    }

    deinit {
        if let app { ghostty_app_free(app) }
        ghostty_config_free(config)
    }

    func setFocus(_ focused: Bool) {
        ghostty_app_set_focus(app, focused)
    }

    // MARK: Config

    /// Bundled Tokyo Night defaults first, then the user's own overrides. Ghostty's
    /// own config files are deliberately not loaded, so a personal Ghostty setup
    /// cannot change Unshell's keybindings behind its back.
    private static func loadConfig(_ config: ghostty_config_t) {
        if let bundled = Bundle.main.path(forResource: "unshell-ghostty", ofType: "conf") {
            ghostty_config_load_file(config, bundled)
        } else {
            log.warning("bundled unshell-ghostty.conf missing; using libghostty defaults")
        }

        let user = (("~/.config/unshell/ghostty.conf") as NSString).expandingTildeInPath
        if FileManager.default.fileExists(atPath: user) {
            ghostty_config_load_file(config, user)
        }

        ghostty_config_finalize(config)

        let count = ghostty_config_diagnostics_count(config)
        for index in 0..<count {
            let diagnostic = ghostty_config_get_diagnostic(config, index)
            if let message = diagnostic.message {
                log.error("config: \(String(cString: message), privacy: .public)")
            }
        }
    }

    // MARK: Callbacks (C function pointers: static, no captures)

    private static func runtime(fromApp app: ghostty_app_t?) -> GhosttyRuntime? {
        guard let app, let raw = ghostty_app_userdata(app) else { return nil }
        return Unmanaged<GhosttyRuntime>.fromOpaque(raw).takeUnretainedValue()
    }

    private static func wakeup(_ userdata: UnsafeMutableRawPointer?) {
        guard let userdata else { return }
        let runtime = Unmanaged<GhosttyRuntime>.fromOpaque(userdata).takeUnretainedValue()
        let shouldSchedule = runtime.tickLock.withLock { (pending: inout Bool) -> Bool in
            if pending { return false }
            pending = true
            return true
        }
        guard shouldSchedule else { return }
        DispatchQueue.main.async {
            runtime.tickLock.withLock { (pending: inout Bool) in pending = false }
            ghostty_app_tick(runtime.app)
        }
    }

    private static func action(_ app: ghostty_app_t?, target: ghostty_target_s, action: ghostty_action_s) -> Bool {
        guard let runtime = runtime(fromApp: app) else { return false }

        var view: TerminalSurfaceView?
        if target.tag == GHOSTTY_TARGET_SURFACE, let surface = target.target.surface {
            view = TerminalSurfaceView.from(userdata: ghostty_surface_userdata(surface))
        }

        switch action.tag {
        case GHOSTTY_ACTION_NEW_TAB, GHOSTTY_ACTION_NEW_WINDOW, GHOSTTY_ACTION_NEW_SPLIT:
            // Splits come later; for now every "new" request opens a terminal in the list.
            runtime.delegate?.ghosttyNewTerminal(from: view)
            return true

        case GHOSTTY_ACTION_CLOSE_TAB:
            guard let view else { return false }
            // Never free a surface from inside libghostty's own tick.
            DispatchQueue.main.async { runtime.delegate?.ghosttyCloseTerminal(view, processAlive: true) }
            return true

        case GHOSTTY_ACTION_GOTO_TAB:
            runtime.delegate?.ghosttyGotoTerminal(action.action.goto_tab)
            return true

        case GHOSTTY_ACTION_SET_TITLE, GHOSTTY_ACTION_SET_TAB_TITLE:
            guard let view, let raw = action.action.set_title.title else { return false }
            runtime.delegate?.ghosttyTitleChanged(view, title: String(cString: raw))
            return true

        case GHOSTTY_ACTION_PWD:
            guard let view, let raw = action.action.pwd.pwd else { return false }
            runtime.delegate?.ghosttyWorkingDirectoryChanged(view, path: String(cString: raw))
            return true

        case GHOSTTY_ACTION_MOUSE_SHAPE:
            view?.setCursorShape(action.action.mouse_shape)
            return true

        case GHOSTTY_ACTION_MOUSE_VISIBILITY:
            NSCursor.setHiddenUntilMouseMoves(action.action.mouse_visibility == GHOSTTY_MOUSE_HIDDEN)
            return true

        case GHOSTTY_ACTION_OPEN_URL:
            let payload = action.action.open_url
            guard let raw = payload.url else { return false }
            let data = Data(bytes: raw, count: Int(payload.len))
            guard let string = String(data: data, encoding: .utf8) else { return false }
            let url = URL(string: string) ?? URL(fileURLWithPath: string)
            NSWorkspace.shared.open(url)
            return true

        case GHOSTTY_ACTION_RING_BELL:
            NSSound.beep()
            return true

        default:
            // Unhandled actions fall back to libghostty's default behaviour.
            return false
        }
    }

    private static func readClipboard(
        _ userdata: UnsafeMutableRawPointer?,
        location: ghostty_clipboard_e,
        state: UnsafeMutableRawPointer?,
        mimes: UnsafePointer<UnsafePointer<CChar>?>?,
        mimesLen: Int,
        list: Bool
    ) -> ghostty_clipboard_read_result_e {
        guard location == GHOSTTY_CLIPBOARD_STANDARD,
              let view = TerminalSurfaceView.from(userdata: userdata),
              let surface = view.surface
        else { return GHOSTTY_CLIPBOARD_READ_UNSUPPORTED }

        // Text only for now. Images/rich types come when an agent needs them.
        var wantsText = list
        if let mimes {
            for index in 0..<mimesLen {
                guard let ptr = mimes[index] else { continue }
                if String(cString: ptr).hasPrefix("text/plain") { wantsText = true }
            }
        }
        guard wantsText, let text = NSPasteboard.general.string(forType: .string) else {
            return list ? completeClipboard(surface, text: nil, state: state) : GHOSTTY_CLIPBOARD_READ_UNAVAILABLE
        }
        return completeClipboard(surface, text: text, state: state)
    }

    private static func completeClipboard(
        _ surface: ghostty_surface_t,
        text: String?,
        state: UnsafeMutableRawPointer?
    ) -> ghostty_clipboard_read_result_e {
        guard let mime = strdup("text/plain;charset=utf-8"), let data = strdup(text ?? "") else {
            return GHOSTTY_CLIPBOARD_READ_UNAVAILABLE
        }
        defer {
            free(mime)
            free(data)
        }
        let hasText = text != nil
        let content = ghostty_clipboard_content_s(mime: UnsafePointer(mime), data: UnsafePointer(data), len: strlen(data))
        let available: [UnsafePointer<CChar>?] = [UnsafePointer(mime)]

        return withUnsafePointer(to: content) { contentPtr in
            available.withUnsafeBufferPointer { availablePtr in
                var complete = ghostty_clipboard_complete_s(
                    contents: hasText ? contentPtr : nil,
                    contents_len: hasText ? 1 : 0,
                    available: hasText ? availablePtr.baseAddress : nil,
                    available_len: hasText ? 1 : 0,
                    confirmed: false,
                    remember: false
                )
                ghostty_surface_complete_clipboard_request(surface, &complete, state)
                return GHOSTTY_CLIPBOARD_READ_STARTED
            }
        }
    }

    private static func writeClipboard(
        _ userdata: UnsafeMutableRawPointer?,
        location: ghostty_clipboard_e,
        content: UnsafePointer<ghostty_clipboard_content_s>?,
        len: Int,
        confirm: Bool
    ) {
        // Writes needing confirmation are disabled by config; ignore them.
        guard location == GHOSTTY_CLIPBOARD_STANDARD, !confirm, let content, len > 0 else { return }
        for index in 0..<len {
            let item = content[index]
            guard let mime = item.mime, String(cString: mime).hasPrefix("text/plain"), let data = item.data else { continue }
            let bytes = Data(bytes: data, count: item.len)
            guard let string = String(data: bytes, encoding: .utf8) else { continue }
            DispatchQueue.main.async {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(string, forType: .string)
            }
            return
        }
    }
}

import AppKit
import Carbon.HIToolbox
import GhosttyKit

/// One terminal. libghostty attaches a CAMetalLayer to this view and renders into
/// it on its own renderer thread; the PTY lives on its own IO thread. This view
/// only forwards size, focus, visibility and input.
final class TerminalSurfaceView: NSView, NSTextInputClient {
    let id = UUID()
    private(set) var surface: ghostty_surface_t?
    private(set) weak var runtime: GhosttyRuntime?

    var title: String = "shell"
    var workingDirectory: String?
    /// Explicit command, or nil for the user's login shell. Kept for restarts.
    let command: String?

    /// Set once the child process exits. The surface stays alive (libghostty is
    /// told to wait after the command), so the scrollback remains readable.
    private(set) var exitStatus: ExitStatus?
    var hasExited: Bool { exitStatus != nil }

    /// Return on an exited terminal asks the window to restart it.
    var onRestartRequested: ((TerminalSurfaceView) -> Void)?

    struct ExitStatus {
        /// libghostty cannot report a reliable code through macOS login(1).
        let code: UInt32
        let runtimeMs: UInt64
    }

    /// Text produced by `interpretKeyEvents` during a keyDown (IME commits).
    private var keyTextAccumulator: [String]?
    private var markedText = NSMutableAttributedString()
    private var trackingArea: NSTrackingArea?
    private var isVisibleToUser = true

    static func from(userdata: UnsafeMutableRawPointer?) -> TerminalSurfaceView? {
        guard let userdata else { return nil }
        return Unmanaged<TerminalSurfaceView>.fromOpaque(userdata).takeUnretainedValue()
    }

    init(runtime: GhosttyRuntime, workingDirectory: String? = nil, command: String? = nil) {
        self.runtime = runtime
        self.command = command
        super.init(frame: NSRect(x: 0, y: 0, width: 800, height: 600))

        var config = ghostty_surface_config_new()
        config.platform_tag = GHOSTTY_PLATFORM_MACOS
        config.platform = ghostty_platform_u(macos: ghostty_platform_macos_s(nsview: Unmanaged.passUnretained(self).toOpaque()))
        config.userdata = Unmanaged.passUnretained(self).toOpaque()
        config.scale_factor = Double(NSScreen.main?.backingScaleFactor ?? 2)
        config.context = GHOSTTY_SURFACE_CONTEXT_TAB
        // A shell that exits must never close its terminal (or, for the last
        // one, the window and the app). libghostty reports the exit through
        // GHOSTTY_ACTION_SHOW_CHILD_EXITED and keeps the surface.
        config.wait_after_command = true

        let cwd = workingDirectory ?? FileManager.default.homeDirectoryForCurrentUser.path
        self.workingDirectory = cwd
        surface = cwd.withCString { cwdPtr in
            config.working_directory = cwdPtr
            // UNSHELL=1 lets shell rc files tell Unshell terminals apart (for
            // example, to skip auto-attaching every terminal to one tmux session).
            return "UNSHELL".withCString { keyPtr in
                "1".withCString { valuePtr in
                    var env = [ghostty_env_var_s(key: keyPtr, value: valuePtr)]
                    return env.withUnsafeMutableBufferPointer { envPtr in
                        config.env_vars = envPtr.baseAddress
                        config.env_var_count = envPtr.count
                        if let command {
                            return command.withCString { commandPtr in
                                config.command = commandPtr
                                return ghostty_surface_new(runtime.app, &config)
                            }
                        }
                        return ghostty_surface_new(runtime.app, &config)
                    }
                }
            }
        }

        if surface == nil {
            GhosttyRuntime.log.error("ghostty_surface_new failed")
        }
        updateTrackingAreas()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not used") }

    func markExited(code: UInt32, runtimeMs: UInt64) {
        exitStatus = ExitStatus(code: code, runtimeMs: runtimeMs)
    }

    /// Must be called before the view is released; libghostty holds a pointer to it.
    func destroy() {
        guard let surface else { return }
        self.surface = nil
        ghostty_surface_free(surface)
    }

    // MARK: Visibility and focus

    /// Off-screen terminals keep their PTY and IO thread running but stop rendering.
    func setVisibleToUser(_ visible: Bool) {
        guard visible != isVisibleToUser else { return }
        isVisibleToUser = visible
        isHidden = !visible
        if let surface { ghostty_surface_set_occlusion(surface, visible) }
    }

    override var acceptsFirstResponder: Bool { true }

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result, let surface { ghostty_surface_set_focus(surface, true) }
        return result
    }

    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result, let surface { ghostty_surface_set_focus(surface, false) }
        return result
    }

    // MARK: Size and scale

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        pushSize()
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        if let window {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer?.contentsScale = window.backingScaleFactor
            CATransaction.commit()
        }
        guard let surface, frame.width > 0, frame.height > 0 else { return }
        let backing = convertToBacking(frame)
        ghostty_surface_set_content_scale(surface, backing.width / frame.width, backing.height / frame.height)
        pushSize()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        viewDidChangeBackingProperties()
    }

    private func pushSize() {
        guard let surface else { return }
        let backing = convertToBacking(NSRect(origin: .zero, size: frame.size))
        guard backing.width > 0, backing.height > 0 else { return }
        ghostty_surface_set_size(surface, UInt32(backing.width), UInt32(backing.height))
    }

    // MARK: Keyboard

    override func keyDown(with event: NSEvent) {
        // libghostty closes an exited surface on any key that encodes text, so
        // keys never reach it once the process is gone: Return restarts.
        if hasExited {
            if event.keyCode == UInt16(kVK_Return) || event.keyCode == UInt16(kVK_ANSI_KeypadEnter) {
                onRestartRequested?(self)
            }
            return
        }
        guard let surface else {
            interpretKeyEvents([event])
            return
        }

        let action = event.isARepeat ? GHOSTTY_ACTION_REPEAT : GHOSTTY_ACTION_PRESS
        // Ghostty may change which modifiers apply to text translation (e.g.
        // macos-option-as-alt). Keep hidden device bits by toggling only the four
        // standard flags, and reuse the original event when nothing changed: IMEs
        // such as Korean depend on event identity.
        let ghosttyTranslation = GhosttyInput.eventModifierFlags(
            ghostty_surface_key_translation_mods(surface, GhosttyInput.ghosttyMods(event.modifierFlags))
        )
        var translationMods = event.modifierFlags
        for flag in [NSEvent.ModifierFlags.shift, .control, .option, .command] {
            if ghosttyTranslation.contains(flag) { translationMods.insert(flag) } else { translationMods.remove(flag) }
        }
        var translationEvent = event
        if translationMods != event.modifierFlags,
           let rebuilt = NSEvent.keyEvent(
               with: event.type,
               location: event.locationInWindow,
               modifierFlags: translationMods,
               timestamp: event.timestamp,
               windowNumber: event.windowNumber,
               context: nil,
               characters: event.characters(byApplyingModifiers: translationMods) ?? "",
               charactersIgnoringModifiers: event.charactersIgnoringModifiers ?? "",
               isARepeat: event.isARepeat,
               keyCode: event.keyCode
           ) {
            translationEvent = rebuilt
        }

        let hadMarkedText = markedText.length > 0
        keyTextAccumulator = []
        defer { keyTextAccumulator = nil }
        interpretKeyEvents([translationEvent])
        syncPreedit()

        let composing = markedText.length > 0 || hadMarkedText
        if let committed = keyTextAccumulator, !committed.isEmpty {
            for text in committed {
                sendKey(action, event: event, translationEvent: translationEvent, text: text)
            }
        } else {
            sendKey(action, event: event, translationEvent: translationEvent,
                    text: GhosttyInput.characters(for: translationEvent), composing: composing)
        }
    }

    override func keyUp(with event: NSEvent) {
        if hasExited { return }
        sendKey(GHOSTTY_ACTION_RELEASE, event: event)
    }

    override func flagsChanged(with event: NSEvent) {
        if hasExited { return }
        guard let modifier = GhosttyInput.modifierFlag(forKeyCode: event.keyCode) else { return }
        let pressed = event.modifierFlags.contains(modifier)
        sendKey(pressed ? GHOSTTY_ACTION_PRESS : GHOSTTY_ACTION_RELEASE, event: event)
    }

    /// Cmd/Ctrl chords arrive here before keyDown. Let libghostty claim the ones
    /// bound in its config (copy, paste, new tab...); everything else goes to the menu.
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.type == .keyDown, window?.firstResponder === self, !hasExited, let surface else { return false }
        var keyEvent = GhosttyInput.keyEvent(for: event, action: GHOSTTY_ACTION_PRESS)
        var flags = ghostty_binding_flags_e(rawValue: 0)
        let isBinding = (event.characters ?? "").withCString { ptr -> Bool in
            keyEvent.text = ptr
            return ghostty_surface_key_is_binding(surface, keyEvent, &flags)
        }
        if isBinding {
            keyDown(with: event)
            return true
        }
        // Ctrl+key chords that AppKit would otherwise swallow (e.g. ctrl+enter).
        if event.modifierFlags.contains(.control) && !event.modifierFlags.contains(.command) {
            keyDown(with: event)
            return true
        }
        return false
    }

    private func sendKey(
        _ action: ghostty_input_action_e,
        event: NSEvent,
        translationEvent: NSEvent? = nil,
        text: String? = nil,
        composing: Bool = false
    ) {
        guard let surface else { return }
        var keyEvent = GhosttyInput.keyEvent(for: event, action: action, translationMods: translationEvent?.modifierFlags)
        keyEvent.composing = composing
        if let text, !text.isEmpty {
            text.withCString { ptr in
                keyEvent.text = ptr
                _ = ghostty_surface_key(surface, keyEvent)
            }
        } else {
            _ = ghostty_surface_key(surface, keyEvent)
        }
    }

    /// Prevent NSBeep for unhandled selectors from interpretKeyEvents.
    override func doCommand(by selector: Selector) {}

    // MARK: NSTextInputClient (IME)

    func insertText(_ string: Any, replacementRange: NSRange) {
        let text: String
        switch string {
        case let value as NSAttributedString: text = value.string
        case let value as String: text = value
        default: return
        }
        unmarkText()
        if keyTextAccumulator != nil {
            keyTextAccumulator?.append(text)
            return
        }
        // Text not tied to a keyDown (dictation, emoji picker): send as committed input.
        guard let surface, !text.isEmpty, !hasExited else { return }
        var keyEvent = ghostty_input_key_s()
        keyEvent.action = GHOSTTY_ACTION_PRESS
        keyEvent.mods = GHOSTTY_MODS_NONE
        keyEvent.consumed_mods = GHOSTTY_MODS_NONE
        text.withCString { ptr in
            keyEvent.text = ptr
            _ = ghostty_surface_key(surface, keyEvent)
        }
    }

    func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
        switch string {
        case let value as NSAttributedString: markedText = NSMutableAttributedString(attributedString: value)
        case let value as String: markedText = NSMutableAttributedString(string: value)
        default: return
        }
        if keyTextAccumulator == nil { syncPreedit() }
    }

    func unmarkText() {
        guard markedText.length > 0 else { return }
        markedText.mutableString.setString("")
        syncPreedit()
    }

    private func syncPreedit() {
        guard let surface else { return }
        if markedText.length > 0 {
            let string = markedText.string
            string.withCString { ptr in
                ghostty_surface_preedit(surface, ptr, UInt(string.utf8.count))
            }
        } else {
            ghostty_surface_preedit(surface, nil, 0)
        }
    }

    func hasMarkedText() -> Bool { markedText.length > 0 }
    func markedRange() -> NSRange { markedText.length > 0 ? NSRange(location: 0, length: markedText.length) : NSRange(location: NSNotFound, length: 0) }
    func selectedRange() -> NSRange { NSRange(location: NSNotFound, length: 0) }
    func validAttributesForMarkedText() -> [NSAttributedString.Key] { [] }
    func attributedSubstring(forProposedRange range: NSRange, actualRange: NSRangePointer?) -> NSAttributedString? { nil }
    func characterIndex(for point: NSPoint) -> Int { 0 }

    func firstRect(forCharacterRange range: NSRange, actualRange: NSRangePointer?) -> NSRect {
        guard let surface, let window else { return .zero }
        var x = 0.0, y = 0.0, width = 0.0, height = 0.0
        ghostty_surface_ime_point(surface, &x, &y, &width, &height)
        // libghostty reports top-left origin in points; AppKit wants screen coords.
        let viewRect = NSRect(x: x, y: frame.height - y, width: width, height: max(height, 1))
        return window.convertToScreen(convert(viewRect, to: nil))
    }

    // MARK: Mouse

    override func updateTrackingAreas() {
        if let trackingArea { removeTrackingArea(trackingArea) }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .mouseMoved, .inVisibleRect, .activeAlways],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
        super.updateTrackingAreas()
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        mouseButton(GHOSTTY_MOUSE_PRESS, GHOSTTY_MOUSE_LEFT, event)
    }

    override func mouseUp(with event: NSEvent) { mouseButton(GHOSTTY_MOUSE_RELEASE, GHOSTTY_MOUSE_LEFT, event) }
    override func rightMouseDown(with event: NSEvent) {
        if !mouseButton(GHOSTTY_MOUSE_PRESS, GHOSTTY_MOUSE_RIGHT, event) { super.rightMouseDown(with: event) }
    }
    override func rightMouseUp(with event: NSEvent) {
        if !mouseButton(GHOSTTY_MOUSE_RELEASE, GHOSTTY_MOUSE_RIGHT, event) { super.rightMouseUp(with: event) }
    }
    override func otherMouseDown(with event: NSEvent) { mouseButton(GHOSTTY_MOUSE_PRESS, GHOSTTY_MOUSE_MIDDLE, event) }
    override func otherMouseUp(with event: NSEvent) { mouseButton(GHOSTTY_MOUSE_RELEASE, GHOSTTY_MOUSE_MIDDLE, event) }

    @discardableResult
    private func mouseButton(_ state: ghostty_input_mouse_state_e, _ button: ghostty_input_mouse_button_e, _ event: NSEvent) -> Bool {
        guard let surface else { return false }
        return ghostty_surface_mouse_button(surface, state, button, GhosttyInput.ghosttyMods(event.modifierFlags))
    }

    override func mouseMoved(with event: NSEvent) { mousePosition(event) }
    override func mouseDragged(with event: NSEvent) { mousePosition(event) }
    override func rightMouseDragged(with event: NSEvent) { mousePosition(event) }
    override func otherMouseDragged(with event: NSEvent) { mousePosition(event) }
    override func mouseEntered(with event: NSEvent) { mousePosition(event) }

    override func mouseExited(with event: NSEvent) {
        guard let surface else { return }
        // Negative coordinates tell libghostty the pointer left the surface.
        ghostty_surface_mouse_pos(surface, -1, -1, GhosttyInput.ghosttyMods(event.modifierFlags))
    }

    private func mousePosition(_ event: NSEvent) {
        guard let surface else { return }
        let point = convert(event.locationInWindow, from: nil)
        ghostty_surface_mouse_pos(surface, point.x, frame.height - point.y, GhosttyInput.ghosttyMods(event.modifierFlags))
    }

    override func scrollWheel(with event: NSEvent) {
        guard let surface else { return }
        var x = event.scrollingDeltaX
        var y = event.scrollingDeltaY
        let precise = event.hasPreciseScrollingDeltas
        if precise {
            x *= 2
            y *= 2
        }
        ghostty_surface_mouse_scroll(surface, x, y, GhosttyInput.scrollMods(precise: precise, phase: event.momentumPhase))
    }

    func setCursorShape(_ shape: ghostty_action_mouse_shape_e) {
        switch shape {
        case GHOSTTY_MOUSE_SHAPE_TEXT: NSCursor.iBeam.set()
        case GHOSTTY_MOUSE_SHAPE_POINTER: NSCursor.pointingHand.set()
        case GHOSTTY_MOUSE_SHAPE_CROSSHAIR: NSCursor.crosshair.set()
        default: NSCursor.arrow.set()
        }
    }

    // MARK: Edit menu

    @objc func copy(_ sender: Any?) { bindingAction("copy_to_clipboard") }
    @objc func paste(_ sender: Any?) { bindingAction("paste_from_clipboard") }
    @objc override func selectAll(_ sender: Any?) { bindingAction("select_all") }

    private func bindingAction(_ name: String) {
        guard let surface else { return }
        _ = ghostty_surface_binding_action(surface, name, UInt(name.utf8.count))
    }
}

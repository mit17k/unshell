import AppKit
import Carbon.HIToolbox
import GhosttyKit

/// NSEvent <-> libghostty input translation. Mirrors the conventions of
/// Ghostty's own macOS app so key encoding (kitty protocol, option-as-alt, dead
/// keys) behaves the same as in Ghostty.
enum GhosttyInput {
    static func ghosttyMods(_ flags: NSEvent.ModifierFlags) -> ghostty_input_mods_e {
        var mods = GHOSTTY_MODS_NONE.rawValue
        if flags.contains(.shift) { mods |= GHOSTTY_MODS_SHIFT.rawValue }
        if flags.contains(.control) { mods |= GHOSTTY_MODS_CTRL.rawValue }
        if flags.contains(.option) { mods |= GHOSTTY_MODS_ALT.rawValue }
        if flags.contains(.command) { mods |= GHOSTTY_MODS_SUPER.rawValue }
        if flags.contains(.capsLock) { mods |= GHOSTTY_MODS_CAPS.rawValue }

        let raw = flags.rawValue
        if raw & UInt(NX_DEVICERSHIFTKEYMASK) != 0 { mods |= GHOSTTY_MODS_SHIFT_RIGHT.rawValue }
        if raw & UInt(NX_DEVICERCTLKEYMASK) != 0 { mods |= GHOSTTY_MODS_CTRL_RIGHT.rawValue }
        if raw & UInt(NX_DEVICERALTKEYMASK) != 0 { mods |= GHOSTTY_MODS_ALT_RIGHT.rawValue }
        if raw & UInt(NX_DEVICERCMDKEYMASK) != 0 { mods |= GHOSTTY_MODS_SUPER_RIGHT.rawValue }
        return ghostty_input_mods_e(rawValue: mods)
    }

    static func eventModifierFlags(_ mods: ghostty_input_mods_e) -> NSEvent.ModifierFlags {
        var flags = NSEvent.ModifierFlags()
        if mods.rawValue & GHOSTTY_MODS_SHIFT.rawValue != 0 { flags.insert(.shift) }
        if mods.rawValue & GHOSTTY_MODS_CTRL.rawValue != 0 { flags.insert(.control) }
        if mods.rawValue & GHOSTTY_MODS_ALT.rawValue != 0 { flags.insert(.option) }
        if mods.rawValue & GHOSTTY_MODS_SUPER.rawValue != 0 { flags.insert(.command) }
        return flags
    }

    /// Builds a key event without `text`; the caller sets text inside a
    /// `withCString` scope so the pointer stays valid for the call.
    static func keyEvent(
        for event: NSEvent,
        action: ghostty_input_action_e,
        translationMods: NSEvent.ModifierFlags? = nil
    ) -> ghostty_input_key_s {
        var key = ghostty_input_key_s()
        key.action = action
        key.keycode = UInt32(event.keyCode)
        key.text = nil
        key.composing = false
        key.mods = ghosttyMods(event.modifierFlags)
        // Control and command never contribute to text translation on macOS.
        key.consumed_mods = ghosttyMods((translationMods ?? event.modifierFlags).subtracting([.control, .command]))
        key.unshifted_codepoint = 0
        if event.type == .keyDown || event.type == .keyUp,
           let scalar = event.characters(byApplyingModifiers: [])?.unicodeScalars.first {
            key.unshifted_codepoint = scalar.value
        }
        return key
    }

    /// Text to attach to a key event. Control characters are encoded by
    /// libghostty itself, and function keys (Private Use Area) carry no text.
    static func characters(for event: NSEvent) -> String? {
        guard let characters = event.characters else { return nil }
        if characters.count == 1, let scalar = characters.unicodeScalars.first {
            if scalar.value < 0x20 {
                return event.characters(byApplyingModifiers: event.modifierFlags.subtracting(.control))
            }
            if (0xF700...0xF8FF).contains(scalar.value) { return nil }
        }
        return characters
    }

    static func modifierFlag(forKeyCode keyCode: UInt16) -> NSEvent.ModifierFlags? {
        switch Int(keyCode) {
        case kVK_Shift, kVK_RightShift: return .shift
        case kVK_Control, kVK_RightControl: return .control
        case kVK_Option, kVK_RightOption: return .option
        case kVK_Command, kVK_RightCommand: return .command
        case kVK_CapsLock: return .capsLock
        default: return nil
        }
    }

    /// Packed like Ghostty's ScrollMods: bit 0 precision, bits 1-3 momentum phase.
    static func scrollMods(precise: Bool, phase: NSEvent.Phase) -> ghostty_input_scroll_mods_t {
        var value: Int32 = precise ? 1 : 0
        let momentum: ghostty_input_mouse_momentum_e
        switch phase {
        case .began: momentum = GHOSTTY_MOUSE_MOMENTUM_BEGAN
        case .stationary: momentum = GHOSTTY_MOUSE_MOMENTUM_STATIONARY
        case .changed: momentum = GHOSTTY_MOUSE_MOMENTUM_CHANGED
        case .ended: momentum = GHOSTTY_MOUSE_MOMENTUM_ENDED
        case .cancelled: momentum = GHOSTTY_MOUSE_MOMENTUM_CANCELLED
        case .mayBegin: momentum = GHOSTTY_MOUSE_MOMENTUM_MAY_BEGIN
        default: momentum = GHOSTTY_MOUSE_MOMENTUM_NONE
        }
        value |= Int32(momentum.rawValue) << 1
        return value
    }
}

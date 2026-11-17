import AppKit

/// Swift port of apps/unshell-desktop/src/renderer/tokens.css (Tokyo Night on an
/// editorial, hairline layout). Use the semantic names; raw palette values only
/// feed them.
enum Theme {
    enum Palette {
        static let bgDeep = NSColor(hex: 0x101014)
        static let bgDark = NSColor(hex: 0x16161E)
        static let bg = NSColor(hex: 0x1A1B26)
        static let bgStorm = NSColor(hex: 0x1F2335)
        static let bgHighlight = NSColor(hex: 0x292E42)
        static let gutter = NSColor(hex: 0x3B4261)
        static let terminalBlack = NSColor(hex: 0x414868)
        static let comment = NSColor(hex: 0x565F89)
        static let dark5 = NSColor(hex: 0x737AA2)
        static let fgDark = NSColor(hex: 0xA9B1D6)
        static let fg = NSColor(hex: 0xC0CAF5)
        static let fgBright = NSColor(hex: 0xDFE5FD)
        static let blue = NSColor(hex: 0x7AA2F7)
        static let cyan = NSColor(hex: 0x7DCFFF)
        static let teal = NSColor(hex: 0x73DACA)
        static let green = NSColor(hex: 0x9ECE6A)
        static let yellow = NSColor(hex: 0xE0AF68)
        static let orange = NSColor(hex: 0xFF9E64)
        static let red = NSColor(hex: 0xF7768E)
        static let magenta = NSColor(hex: 0xBB9AF7)
    }

    enum Color {
        static let canvas = Palette.bgDark
        static let bg = Palette.bg
        static let surfaceRaised = Palette.bgStorm
        static let surfaceHover = Palette.bgHighlight
        static let surfaceSunken = Palette.bgDeep
        static let rule = NSColor(hex: 0x2C3148)
        static let ruleSubtle = NSColor(hex: 0x222432)
        static let fg = Palette.fg
        static let fgStrong = Palette.fgBright
        static let fgSecondary = Palette.fgDark
        static let fgMuted = Palette.dark5
        static let fgFaint = Palette.comment
        static let accent = Palette.orange
        static let info = Palette.blue
        static let success = Palette.green
        static let warning = Palette.yellow
        static let danger = Palette.red
        static let link = Palette.cyan
        static let focus = Palette.blue
        static let selection = Palette.blue.withAlphaComponent(0.28)
    }

    enum Font {
        static let mono = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        /// Uppercase operational metadata (status bar, labels).
        static let monoLabel = NSFont.monospacedSystemFont(ofSize: 10.5, weight: .medium)
        static let body = NSFont.systemFont(ofSize: 14)
        static let display = NSFont(descriptor: NSFont.systemFont(ofSize: 32).fontDescriptor.withDesign(.serif) ?? NSFont.systemFont(ofSize: 32).fontDescriptor, size: 32)
            ?? NSFont.systemFont(ofSize: 32)
    }
}

extension NSColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

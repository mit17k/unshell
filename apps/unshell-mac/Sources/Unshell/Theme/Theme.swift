import AppKit
import QuartzCore

/// Swift port of apps/unshell-desktop/src/renderer/tokens.css: Tokyo Night on an
/// editorial, hairline layout. Views use the semantic names (`Theme.Color`,
/// `Theme.Space`, `Theme.Type`...); raw `Palette` values only feed them.
enum Theme {
    // MARK: Colour

    /// Tokyo Night (night) palette. `--tn-*`.
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

        /// Name/colour pairs in token order, for specimens.
        static let all: [(String, NSColor)] = [
            ("bg-deep", bgDeep), ("bg-dark", bgDark), ("bg", bg), ("bg-storm", bgStorm),
            ("bg-highlight", bgHighlight), ("gutter", gutter), ("terminal-black", terminalBlack),
            ("comment", comment), ("dark5", dark5), ("fg-dark", fgDark), ("fg", fg),
            ("fg-bright", fgBright), ("blue", blue), ("cyan", cyan), ("teal", teal),
            ("green", green), ("yellow", yellow), ("orange", orange), ("red", red),
            ("magenta", magenta),
        ]
    }

    /// Semantic colours. `--color-*`.
    enum Color {
        // Surfaces
        static let canvas = Palette.bgDark
        static let surface = Palette.bg
        static let surfaceRaised = Palette.bgStorm
        static let surfaceHover = Palette.bgHighlight
        static let surfaceSunken = Palette.bgDeep
        static let overlay = NSColor(hex: 0x101014, alpha: 0.72)

        // Lines
        static let borderSubtle = NSColor(hex: 0x222432)
        static let border = NSColor(hex: 0x2C3148)
        static let borderStrong = Palette.terminalBlack

        // Text
        static let text = Palette.fg
        static let textStrong = Palette.fgBright
        static let textSecondary = Palette.fgDark
        static let textMuted = Palette.dark5
        static let textFaint = Palette.comment

        // Intent
        static let primary = Palette.fg
        static let primaryHover = Palette.fgBright
        static let onPrimary = Palette.bgDark
        static let accent = Palette.orange
        static let info = Palette.blue
        static let success = Palette.green
        static let warning = Palette.yellow
        static let danger = Palette.red
        static let highlight = Palette.magenta
        static let link = Palette.cyan
        static let focus = Palette.blue
        static let selection = Palette.blue.withAlphaComponent(0.28)

        // Older names used by the terminal window.
        static let bg = surface
        static let fg = text
        static let fgStrong = textStrong
        static let fgSecondary = textSecondary
        static let fgMuted = textMuted
        static let fgFaint = textFaint
        static let rule = border
        static let ruleSubtle = borderSubtle

        static let groups: [(String, [(String, NSColor)])] = [
            ("Surface", [("canvas", canvas), ("surface", surface), ("surface-raised", surfaceRaised),
                         ("surface-hover", surfaceHover), ("surface-sunken", surfaceSunken)]),
            ("Line", [("border-subtle", borderSubtle), ("border", border), ("border-strong", borderStrong)]),
            ("Text", [("text-strong", textStrong), ("text", text), ("text-secondary", textSecondary),
                      ("text-muted", textMuted), ("text-faint", textFaint)]),
            ("Intent", [("primary", primary), ("accent", accent), ("info", info), ("success", success),
                        ("warning", warning), ("danger", danger), ("highlight", highlight), ("link", link)]),
        ]
    }

    // MARK: Typography

    enum Family {
        case display, sans, mono
    }

    /// Type scale in points. `--text-*`.
    enum TextSize {
        static let displayXL: CGFloat = 72
        static let displayLG: CGFloat = 48
        static let displayMD: CGFloat = 32
        static let title: CGFloat = 20
        static let bodyLG: CGFloat = 16
        static let body: CGFloat = 14
        static let small: CGFloat = 12
        static let label: CGFloat = 11
    }

    /// Line height multipliers. `--leading-*`.
    enum Leading {
        static let tight: CGFloat = 1.05
        static let snug: CGFloat = 1.3
        static let body: CGFloat = 1.6
    }

    /// `--weight-*`.
    enum Weight {
        static let regular = NSFont.Weight.regular
        static let medium = NSFont.Weight.medium
        static let semibold = NSFont.Weight.semibold
    }

    /// Letter spacing in em; multiply by the font size for AppKit's `.kern`.
    enum Tracking {
        static let display: CGFloat = -0.02
        static let label: CGFloat = 0.18
    }

    enum Font {
        static func font(_ family: Family, size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
            switch family {
            case .display:
                let base = NSFont.systemFont(ofSize: size, weight: weight)
                if let serif = base.fontDescriptor.withDesign(.serif), let font = NSFont(descriptor: serif, size: size) {
                    return font
                }
                return NSFont(name: "Georgia", size: size) ?? base
            case .sans:
                return NSFont.systemFont(ofSize: size, weight: weight)
            case .mono:
                return NSFont.monospacedSystemFont(ofSize: size, weight: weight)
            }
        }

        static let mono = font(.mono, size: TextSize.small)
        /// Uppercase operational metadata (eyebrows, status bar).
        static let monoLabel = font(.mono, size: TextSize.label, weight: Weight.medium)
        static let body = font(.sans, size: TextSize.body)
        static let display = font(.display, size: TextSize.displayMD)
    }

    // MARK: Layout

    /// 4 pt grid. `--space-*`.
    enum Space {
        static let s0: CGFloat = 0
        static let s1: CGFloat = 4
        static let s2: CGFloat = 8
        static let s3: CGFloat = 12
        static let s4: CGFloat = 16
        static let s5: CGFloat = 20
        static let s6: CGFloat = 24
        static let s8: CGFloat = 32
        static let s10: CGFloat = 40
        static let s12: CGFloat = 48
        static let s16: CGFloat = 64

        static let all: [(String, CGFloat)] = [
            ("1", s1), ("2", s2), ("3", s3), ("4", s4), ("5", s5), ("6", s6),
            ("8", s8), ("10", s10), ("12", s12), ("16", s16),
        ]
    }

    /// Control heights. `--control-*`, `--hairline`.
    enum Size {
        static let controlSM: CGFloat = 28
        static let controlMD: CGFloat = 36
        static let controlLG: CGFloat = 48
        static let hairline: CGFloat = 1
    }

    /// Square by default: the look is drafted, not bubbly. `--radius-*`.
    enum Radius {
        static let none: CGFloat = 0
        static let xs: CGFloat = 2
        static let sm: CGFloat = 4
        static let full: CGFloat = 999
        static let control = xs

        static let all: [(String, CGFloat)] = [("none", none), ("xs", xs), ("sm", sm), ("full", full)]
    }

    // MARK: Elevation

    /// Flat surfaces; shadows only for floating layers. `--shadow-*`.
    struct Shadow {
        let color: NSColor
        let offsetY: CGFloat
        let blur: CGFloat
        /// CSS spread has no CALayer equivalent; negative spread is approximated
        /// by reducing the blur radius.
        let spread: CGFloat
        /// Optional 1 pt ring drawn as a border (the focus glow).
        let ring: NSColor?

        static let none = Shadow(color: .clear, offsetY: 0, blur: 0, spread: 0, ring: nil)
        static let s1 = Shadow(color: NSColor(white: 0, alpha: 0.40), offsetY: 1, blur: 0, spread: 0, ring: nil)
        static let s2 = Shadow(color: NSColor(white: 0, alpha: 0.60), offsetY: 8, blur: 24, spread: -8, ring: nil)
        static let s3 = Shadow(color: NSColor(white: 0, alpha: 0.72), offsetY: 24, blur: 64, spread: -16, ring: nil)
        static let glow = Shadow(color: Palette.blue.withAlphaComponent(0.35), offsetY: 0, blur: 24, spread: -4,
                                 ring: Palette.blue.withAlphaComponent(0.35))

        static let all: [(String, Shadow)] = [("1", s1), ("2", s2), ("3", s3), ("glow", glow)]

        func apply(to layer: CALayer) {
            layer.shadowColor = color.cgColor
            layer.shadowOpacity = color == .clear ? 0 : 1
            // AppKit layers are unflipped: positive CSS y (down) is negative here.
            layer.shadowOffset = CGSize(width: 0, height: -offsetY)
            layer.shadowRadius = max(0, (blur + spread) / 2)
            if let ring {
                layer.borderColor = ring.cgColor
                layer.borderWidth = Size.hairline
            }
        }
    }

    // MARK: Motion

    enum Motion {
        /// Durations in seconds; zero when the user asks for reduced motion.
        static var instant: TimeInterval { scaled(0.080) }
        static var fast: TimeInterval { scaled(0.140) }
        static var base: TimeInterval { scaled(0.220) }
        static var slow: TimeInterval { scaled(0.380) }

        static var reduceMotion: Bool { NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }

        private static func scaled(_ seconds: TimeInterval) -> TimeInterval {
            reduceMotion ? 0 : seconds
        }

        static let standard = CAMediaTimingFunction(controlPoints: 0.2, 0, 0, 1)
        static let emphasized = CAMediaTimingFunction(controlPoints: 0.3, 0, 0, 1)
        static let exit = CAMediaTimingFunction(controlPoints: 0.4, 0, 1, 1)

        static let easings: [(String, CAMediaTimingFunction)] = [
            ("standard", standard), ("emphasized", emphasized), ("exit", exit),
        ]
        static let durationNames = ["instant", "fast", "base", "slow"]

        /// Runs `changes` inside an implicit animation with a token duration and curve.
        static func animate(
            _ duration: TimeInterval = base,
            _ curve: CAMediaTimingFunction = standard,
            _ changes: () -> Void
        ) {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = duration
                context.timingFunction = curve
                context.allowsImplicitAnimation = true
                changes()
            }
        }
    }

    // MARK: Grain

    /// Film grain over the canvas, as in the reference. `--grain-opacity`.
    enum Grain {
        static let opacity: Float = 0.06

        /// 160 pt tile of grey noise, generated once.
        static let tile: NSImage = {
            let size = 160
            var bytes = [UInt8](repeating: 0, count: size * size)
            var generator = SystemRandomNumberGenerator()
            for index in bytes.indices { bytes[index] = UInt8.random(in: 0...255, using: &generator) }
            let provider = CGDataProvider(data: Data(bytes) as CFData)!
            let image = CGImage(
                width: size, height: size, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: size,
                space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: 0),
                provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent
            )!
            return NSImage(cgImage: image, size: NSSize(width: size, height: size))
        }()
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

    /// `#rrggbb`, for specimens.
    var hexString: String {
        guard let rgb = usingColorSpace(.sRGB) else { return "" }
        return String(format: "#%02x%02x%02x",
                      Int(round(rgb.redComponent * 255)), Int(round(rgb.greenComponent * 255)),
                      Int(round(rgb.blueComponent * 255)))
    }
}

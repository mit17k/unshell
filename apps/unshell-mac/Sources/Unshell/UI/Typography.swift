import AppKit

/// Text styles from ui.css, as attributed strings and labels. Port of
/// renderer/ui/Typography.tsx plus the `.u-rule` hairline.
enum UIText {
    /// Builds an attributed string with token type, tracking (em) and leading.
    static func attributed(
        _ string: String,
        family: Theme.Family,
        size: CGFloat,
        weight: NSFont.Weight = .regular,
        color: NSColor = Theme.Color.text,
        tracking: CGFloat = 0,
        leading: CGFloat? = nil,
        uppercase: Bool = false,
        alignment: NSTextAlignment = .natural
    ) -> NSAttributedString {
        let font = Theme.Font.font(family, size: size, weight: weight)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        if let leading {
            paragraph.minimumLineHeight = size * leading
            paragraph.maximumLineHeight = size * leading
        }
        return NSAttributedString(string: uppercase ? string.uppercased() : string, attributes: [
            .font: font,
            .foregroundColor: color,
            .kern: tracking * size,
            .paragraphStyle: paragraph,
        ])
    }

    static func label(_ attributed: NSAttributedString, wraps: Bool = false) -> NSTextField {
        let field = wraps ? NSTextField(wrappingLabelWithString: "") : NSTextField(labelWithString: "")
        field.attributedStringValue = attributed
        field.isSelectable = false
        field.drawsBackground = false
        field.translatesAutoresizingMaskIntoConstraints = false
        if !wraps { field.lineBreakMode = .byTruncatingTail }
        return field
    }

    static func body(_ string: String, size: CGFloat = Theme.TextSize.body, color: NSColor = Theme.Color.text,
                     wraps: Bool = true) -> NSTextField {
        label(attributed(string, family: .sans, size: size, color: color, leading: Theme.Leading.body), wraps: wraps)
    }

    static func mono(_ string: String, size: CGFloat = Theme.TextSize.small,
                     color: NSColor = Theme.Color.textSecondary) -> NSTextField {
        label(attributed(string, family: .mono, size: size, color: color))
    }
}

enum DisplaySize {
    case xl, lg, md

    var points: CGFloat {
        switch self {
        case .xl: return Theme.TextSize.displayXL
        case .lg: return Theme.TextSize.displayLG
        case .md: return Theme.TextSize.displayMD
        }
    }
}

/// Serif display heading. `<Display>`.
func Display(_ text: String, size: DisplaySize = .lg) -> NSTextField {
    UIText.label(UIText.attributed(
        text, family: .display, size: size.points, color: Theme.Color.textStrong,
        tracking: Theme.Tracking.display, leading: Theme.Leading.tight
    ), wraps: true)
}

/// Small uppercase mono label for eyebrows, keys and metadata. `<Eyebrow>`.
func Eyebrow(_ text: String, color: NSColor = Theme.Color.textMuted) -> NSTextField {
    UIText.label(UIText.attributed(
        text, family: .mono, size: Theme.TextSize.label, weight: Theme.Weight.medium,
        color: color, tracking: Theme.Tracking.label, uppercase: true
    ))
}

/// Key cap with a heavier bottom edge. `<Kbd>`.
final class Kbd: NSView {
    init(_ key: String) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = Theme.Color.surface.cgColor
        layer?.borderColor = Theme.Color.border.cgColor
        layer?.borderWidth = Theme.Size.hairline
        layer?.cornerRadius = Theme.Radius.xs
        translatesAutoresizingMaskIntoConstraints = false

        let bottom = Hairline(color: Theme.Color.border)
        let text = UIText.mono(key, color: Theme.Color.textSecondary)
        text.alignment = .center
        addSubview(text)
        addSubview(bottom)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 20),
            widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
            text.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -1),
            text.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Theme.Space.s1),
            text.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Theme.Space.s1),
            bottom.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottom.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottom.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not used") }
}

/// Accent-underlined link; turns accent on hover. `<TextLink>`.
final class TextLink: NSControl {
    private let text: String
    private let url: URL?
    private var hovering = false { didSet { needsDisplay = true } }

    init(_ text: String, url: URL? = nil) {
        self.text = text
        self.url = url
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
                                       owner: self, userInfo: nil))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not used") }

    private var attributed: NSAttributedString {
        let string = NSMutableAttributedString(attributedString: UIText.attributed(
            text, family: .sans, size: Theme.TextSize.body,
            color: hovering ? Theme.Color.accent : Theme.Color.text
        ))
        string.addAttributes([
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .underlineColor: Theme.Color.accent,
            .baselineOffset: 0,
        ], range: NSRange(location: 0, length: string.length))
        return string
    }

    override var intrinsicContentSize: NSSize {
        let size = attributed.size()
        return NSSize(width: ceil(size.width), height: ceil(size.height) + 4)
    }

    override func draw(_ dirtyRect: NSRect) {
        attributed.draw(at: NSPoint(x: 0, y: 2))
    }

    override func mouseEntered(with event: NSEvent) { hovering = true; NSCursor.pointingHand.set() }
    override func mouseExited(with event: NSEvent) { hovering = false; NSCursor.arrow.set() }

    override func mouseDown(with event: NSEvent) {
        if let url { NSWorkspace.shared.open(url) }
        sendAction(action, to: target)
    }
}

/// 1 pt rule. `.u-rule`; horizontal unless `vertical`.
final class Hairline: NSView {
    init(color: NSColor = Theme.Color.borderSubtle, vertical: Bool = false) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = color.cgColor
        translatesAutoresizingMaskIntoConstraints = false
        if vertical {
            widthAnchor.constraint(equalToConstant: Theme.Size.hairline).isActive = true
        } else {
            heightAnchor.constraint(equalToConstant: Theme.Size.hairline).isActive = true
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not used") }
}

/// A flipped container, so stacked content grows downward from the top.
class FlippedView: NSView {
    override var isFlipped: Bool { true }
}

extension NSStackView {
    static func vertical(_ views: [NSView], spacing: CGFloat, alignment: NSLayoutConstraint.Attribute = .leading) -> NSStackView {
        let stack = NSStackView(views: views)
        stack.orientation = .vertical
        stack.alignment = alignment
        stack.spacing = spacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    static func horizontal(_ views: [NSView], spacing: CGFloat, alignment: NSLayoutConstraint.Attribute = .centerY) -> NSStackView {
        let stack = NSStackView(views: views)
        stack.orientation = .horizontal
        stack.alignment = alignment
        stack.spacing = spacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }
}

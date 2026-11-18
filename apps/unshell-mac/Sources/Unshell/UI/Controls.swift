import AppKit

/// Square, mono, uppercase button. Port of renderer/ui/Button.tsx and the
/// `.u-button` rules: four variants, three sizes, a 1 pt press nudge.
final class UButton: NSControl {
    enum Variant { case primary, secondary, ghost, danger }
    enum Size {
        case sm, md, lg

        var height: CGFloat {
            switch self {
            case .sm: return Theme.Size.controlSM
            case .md: return Theme.Size.controlMD
            case .lg: return Theme.Size.controlLG
            }
        }

        var padding: CGFloat {
            switch self {
            case .sm: return Theme.Space.s3
            case .md: return Theme.Space.s4
            case .lg: return Theme.Space.s6
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .sm: return 10
            case .md: return Theme.TextSize.label
            case .lg: return Theme.TextSize.small
            }
        }
    }

    let title: String
    let variant: Variant
    let size: Size
    var onClick: (() -> Void)?

    private let label = NSTextField(labelWithString: "")
    private var hovering = false { didSet { refresh() } }
    private var pressed = false { didSet { refresh() } }

    init(_ title: String, variant: Variant = .secondary, size: Size = .md, onClick: (() -> Void)? = nil) {
        self.title = title
        self.variant = variant
        self.size = size
        self.onClick = onClick
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = Theme.Radius.control
        layer?.borderWidth = Theme.Size.hairline
        translatesAutoresizingMaskIntoConstraints = false

        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: size.height),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: size.padding),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -size.padding),
        ])
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
                                       owner: self, userInfo: nil))
        refresh()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not used") }

    override var isEnabled: Bool { didSet { refresh() } }

    private func colors() -> (border: NSColor, fill: NSColor, text: NSColor) {
        let active = isEnabled && hovering
        switch variant {
        case .primary:
            let fill = active ? Theme.Color.primaryHover : Theme.Color.primary
            return (fill, fill, Theme.Color.onPrimary)
        case .secondary:
            return (active ? Theme.Color.textMuted : Theme.Color.borderStrong,
                    active ? Theme.Color.surfaceHover : .clear, Theme.Color.text)
        case .ghost:
            return (.clear, active ? Theme.Color.surfaceHover : .clear,
                    active ? Theme.Color.textStrong : Theme.Color.textSecondary)
        case .danger:
            return (Theme.Color.danger, active ? Theme.Color.danger.withAlphaComponent(0.12) : .clear, Theme.Color.danger)
        }
    }

    private func refresh() {
        let (border, fill, text) = colors()
        Theme.Motion.animate(Theme.Motion.fast) {
            layer?.borderColor = border.cgColor
            layer?.backgroundColor = fill.cgColor
        }
        alphaValue = isEnabled ? 1 : 0.4
        label.attributedStringValue = UIText.attributed(
            title, family: .mono, size: size.fontSize, weight: Theme.Weight.medium, color: text,
            tracking: Theme.Tracking.label, uppercase: true
        )
        // The press nudge: translateY(1px) while held.
        layer?.sublayerTransform = pressed ? CATransform3DMakeTranslation(0, -1, 0) : CATransform3DIdentity
    }

    override func mouseEntered(with event: NSEvent) { hovering = true }
    override func mouseExited(with event: NSEvent) { hovering = false }

    override func mouseDown(with event: NSEvent) {
        guard isEnabled else { return }
        pressed = true
    }

    override func mouseUp(with event: NSEvent) {
        guard isEnabled, pressed else { return }
        pressed = false
        if bounds.contains(convert(event.locationInWindow, from: nil)) {
            onClick?()
            sendAction(action, to: target)
        }
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: isEnabled ? .pointingHand : .operationNotAllowed)
    }
}

enum Tone {
    case neutral, accent, info, success, warning, danger

    var color: NSColor {
        switch self {
        case .neutral: return Theme.Color.textMuted
        case .accent: return Theme.Color.accent
        case .info: return Theme.Color.info
        case .success: return Theme.Color.success
        case .warning: return Theme.Color.warning
        case .danger: return Theme.Color.danger
        }
    }
}

/// Mono status chip with an optional square dot. Port of renderer/ui/Badge.tsx.
final class Badge: NSView {
    init(_ text: String, tone: Tone = .neutral, dot: Bool = false) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = Theme.Radius.xs
        layer?.borderWidth = Theme.Size.hairline
        layer?.borderColor = (tone == .neutral ? Theme.Color.border : tone.color.withAlphaComponent(0.4)).cgColor
        translatesAutoresizingMaskIntoConstraints = false

        let label = UIText.label(UIText.attributed(
            text, family: .mono, size: Theme.TextSize.label,
            color: tone == .neutral ? Theme.Color.textSecondary : tone.color
        ))
        var views: [NSView] = [label]
        if dot {
            let square = NSView()
            square.wantsLayer = true
            square.layer?.backgroundColor = tone.color.cgColor
            square.translatesAutoresizingMaskIntoConstraints = false
            square.widthAnchor.constraint(equalToConstant: 6).isActive = true
            square.heightAnchor.constraint(equalToConstant: 6).isActive = true
            views.insert(square, at: 0)
        }
        let stack = NSStackView.horizontal(views, spacing: Theme.Space.s2)
        addSubview(stack)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 24),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Theme.Space.s2),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Theme.Space.s2),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not used") }
}

/// Labelled text input with hint or error. Port of renderer/ui/Field.tsx.
final class Field: NSView {
    let input = NSTextField()

    init(label: String, placeholder: String? = nil, value: String = "", hint: String? = nil, error: String? = nil) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        input.stringValue = value
        input.isBordered = false
        input.focusRingType = .none
        input.drawsBackground = false
        input.font = Theme.Font.font(.sans, size: Theme.TextSize.body)
        input.textColor = Theme.Color.text
        if let placeholder {
            input.placeholderAttributedString = UIText.attributed(placeholder, family: .sans, size: Theme.TextSize.body,
                                                                  color: Theme.Color.textFaint)
        }
        input.translatesAutoresizingMaskIntoConstraints = false

        let box = NSView()
        box.wantsLayer = true
        box.layer?.backgroundColor = Theme.Color.surfaceSunken.cgColor
        box.layer?.cornerRadius = Theme.Radius.control
        box.layer?.borderWidth = Theme.Size.hairline
        box.layer?.borderColor = (error != nil ? Theme.Color.danger : Theme.Color.border).cgColor
        box.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(input)
        NSLayoutConstraint.activate([
            box.heightAnchor.constraint(equalToConstant: Theme.Size.controlMD),
            input.centerYAnchor.constraint(equalTo: box.centerYAnchor),
            input.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: Theme.Space.s3),
            input.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -Theme.Space.s3),
        ])

        var views: [NSView] = [Eyebrow(label), box]
        if let message = error ?? hint {
            views.append(UIText.body(message, size: Theme.TextSize.small,
                                     color: error != nil ? Theme.Color.danger : Theme.Color.textMuted, wraps: false))
        }
        let stack = NSStackView.vertical(views, spacing: Theme.Space.s2)
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            box.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not used") }
}

/// Square toggle with a sliding thumb. Port of renderer/ui/Switch.tsx.
final class USwitch: NSControl {
    private(set) var isOn: Bool
    var onChange: ((Bool) -> Void)?
    private let track = NSView()
    private let thumb = NSView()
    private var thumbLeading: NSLayoutConstraint!

    init(_ label: String, isOn: Bool, onChange: ((Bool) -> Void)? = nil) {
        self.isOn = isOn
        self.onChange = onChange
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        track.wantsLayer = true
        track.layer?.cornerRadius = Theme.Radius.xs
        track.layer?.borderWidth = Theme.Size.hairline
        track.translatesAutoresizingMaskIntoConstraints = false
        thumb.wantsLayer = true
        thumb.translatesAutoresizingMaskIntoConstraints = false
        track.addSubview(thumb)
        thumbLeading = thumb.leadingAnchor.constraint(equalTo: track.leadingAnchor, constant: 3)

        let text = UIText.body(label, color: Theme.Color.text, wraps: false)
        let stack = NSStackView.horizontal([track, text], spacing: Theme.Space.s3)
        addSubview(stack)
        NSLayoutConstraint.activate([
            track.widthAnchor.constraint(equalToConstant: 32),
            track.heightAnchor.constraint(equalToConstant: 18),
            thumb.widthAnchor.constraint(equalToConstant: 10),
            thumb.heightAnchor.constraint(equalToConstant: 10),
            thumb.centerYAnchor.constraint(equalTo: track.centerYAnchor),
            thumbLeading,
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        refresh(animated: false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not used") }

    override var isEnabled: Bool { didSet { alphaValue = isEnabled ? 1 : 0.4 } }

    func setOn(_ on: Bool, animated: Bool = true) {
        isOn = on
        refresh(animated: animated)
    }

    private func refresh(animated: Bool) {
        let apply = {
            self.track.layer?.borderColor = (self.isOn ? Theme.Color.info : Theme.Color.borderStrong).cgColor
            self.track.layer?.backgroundColor = (self.isOn ? Theme.Color.info.withAlphaComponent(0.16)
                                                           : Theme.Color.surfaceSunken).cgColor
            self.thumb.layer?.backgroundColor = (self.isOn ? Theme.Color.info : Theme.Color.textMuted).cgColor
            self.thumbLeading.animator().constant = self.isOn ? 17 : 3
            self.track.layoutSubtreeIfNeeded()
        }
        if animated {
            Theme.Motion.animate(Theme.Motion.base, Theme.Motion.emphasized, apply)
        } else {
            apply()
        }
    }

    override func mouseUp(with event: NSEvent) {
        guard isEnabled, bounds.contains(convert(event.locationInWindow, from: nil)) else { return }
        setOn(!isOn)
        onChange?(isOn)
        sendAction(action, to: target)
    }
}

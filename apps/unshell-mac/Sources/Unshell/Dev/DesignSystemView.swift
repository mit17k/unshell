#if DEBUG
import AppKit

/// Design system specimen: palette, semantic colours, type, spacing, radius,
/// elevation, motion and every UI component. Port of
/// renderer/dev/views/DesignSystemView.tsx.
final class DesignSystemView: FlippedView {
    private var motionDots: [NSView] = []
    private var motionMoved = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView.vertical([], spacing: Theme.Space.s16)
        stack.edgeInsets = NSEdgeInsets(top: Theme.Space.s12, left: Theme.Space.s12,
                                        bottom: Theme.Space.s16, right: Theme.Space.s12)
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        let sections: [NSView] = [hero(), colour(), typography(), spacing(), shape(), motion(), components()]
        for section in sections {
            stack.addArrangedSubview(section)
            section.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -2 * Theme.Space.s12).isActive = true
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not used") }

    // MARK: Building blocks

    private func block(_ index: String, _ title: String, _ glyph: String, _ content: [NSView]) -> NSView {
        let header = SectionHeader(index: index, title: title, glyph: glyph)
        let stack = NSStackView.vertical([header] + content, spacing: Theme.Space.s6)
        for view in [header] + content { view.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true }
        return stack
    }

    private func specimen(_ label: String, _ content: [NSView]) -> NSView {
        let body = NSStackView.vertical(content, spacing: Theme.Space.s4)
        let stack = NSStackView.vertical([Eyebrow(label), body], spacing: Theme.Space.s3)
        body.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        return stack
    }

    private func row(_ views: [NSView], spacing: CGFloat = Theme.Space.s3) -> NSStackView {
        NSStackView.horizontal(views, spacing: spacing)
    }

    private func caption(_ text: String) -> NSTextField {
        UIText.mono(text, size: Theme.TextSize.label, color: Theme.Color.textMuted)
    }

    private func swatches(_ colors: [(String, NSColor)], prefix: String) -> NSView {
        let tiles: [NSView] = colors.map { name, color in
            let chip = NSView()
            chip.wantsLayer = true
            chip.layer?.backgroundColor = color.cgColor
            chip.layer?.borderWidth = Theme.Size.hairline
            chip.layer?.borderColor = Theme.Color.borderSubtle.cgColor
            chip.translatesAutoresizingMaskIntoConstraints = false
            chip.widthAnchor.constraint(equalToConstant: 132).isActive = true
            chip.heightAnchor.constraint(equalToConstant: 56).isActive = true
            return NSStackView.vertical([chip, caption("\(prefix)\(name)"), caption(color.hexString)], spacing: Theme.Space.s1)
        }
        // Wrap into rows of six.
        let rows = stride(from: 0, to: tiles.count, by: 6).map { start in
            row(Array(tiles[start..<min(start + 6, tiles.count)]), spacing: Theme.Space.s4)
        }
        return NSStackView.vertical(rows, spacing: Theme.Space.s4)
    }

    // MARK: Sections

    private func hero() -> NSView {
        let lede = UIText.body("Editorial type, hairline rules and square controls on the Tokyo Night palette. "
            + "Everything here reads from Theme.swift and UI/.", size: Theme.TextSize.bodyLG,
            color: Theme.Color.textSecondary)
        lede.preferredMaxLayoutWidth = 620
        return NSStackView.vertical([Eyebrow("Unshell · Design system · Tokyo Night"), Display("Unshell", size: .xl), lede],
                                    spacing: Theme.Space.s4)
    }

    private func colour() -> NSView {
        var content: [NSView] = [specimen("Tokyo Night palette", [swatches(Theme.Palette.all, prefix: "--tn-")])]
        for (group, colors) in Theme.Color.groups {
            content.append(specimen("Semantic · \(group)", [swatches(colors, prefix: "--color-")]))
        }
        return block("01", "Colour", "色", content)
    }

    private func typography() -> NSView {
        let scale: [(String, Theme.Family, CGFloat, String)] = [
            ("display-xl", .display, Theme.TextSize.displayXL, "Unshell"),
            ("display-lg", .display, Theme.TextSize.displayLG, "A place to work."),
            ("display-md", .display, Theme.TextSize.displayMD, "Workspaces, agents, automation."),
            ("title", .sans, Theme.TextSize.title, "Change anything. Reinstall nothing."),
            ("body-lg", .sans, Theme.TextSize.bodyLG, "Every repository, tree and agent in one place."),
            ("body", .sans, Theme.TextSize.body, "Body copy sits at fourteen points with generous leading."),
            ("small", .sans, Theme.TextSize.small, "Small print for notes and secondary detail."),
            ("label", .mono, Theme.TextSize.label, "WORKSPACE · MAIN · CLEAN"),
        ]
        let rows: [NSView] = scale.map { token, family, size, sample in
            let name = caption("--text-\(token)")
            name.widthAnchor.constraint(equalToConstant: 160).isActive = true
            let text = UIText.label(UIText.attributed(
                sample, family: family, size: size,
                color: family == .display ? Theme.Color.textStrong : Theme.Color.text,
                tracking: family == .display ? Theme.Tracking.display : family == .mono ? Theme.Tracking.label : 0,
                leading: family == .display ? Theme.Leading.tight : nil
            ))
            return row([name, text], spacing: Theme.Space.s6)
        }
        return block("02", "Typography", "字", rows)
    }

    private func spacing() -> NSView {
        let rows: [NSView] = Theme.Space.all.map { name, value in
            let label = caption("--space-\(name)")
            label.widthAnchor.constraint(equalToConstant: 160).isActive = true
            let bar = NSView()
            bar.wantsLayer = true
            bar.layer?.backgroundColor = Theme.Color.accent.cgColor
            bar.translatesAutoresizingMaskIntoConstraints = false
            bar.widthAnchor.constraint(equalToConstant: value).isActive = true
            bar.heightAnchor.constraint(equalToConstant: 8).isActive = true
            return row([label, bar, caption("\(Int(value)) pt")], spacing: Theme.Space.s4)
        }
        return block("03", "Spacing", "間", rows)
    }

    private func tile(raised: Bool) -> NSView {
        let tile = NSView()
        tile.wantsLayer = true
        tile.layer?.backgroundColor = (raised ? Theme.Color.surfaceRaised : Theme.Color.surfaceHover).cgColor
        tile.layer?.masksToBounds = false
        tile.translatesAutoresizingMaskIntoConstraints = false
        tile.widthAnchor.constraint(equalToConstant: 96).isActive = true
        tile.heightAnchor.constraint(equalToConstant: 64).isActive = true
        return tile
    }

    private func shape() -> NSView {
        let radii: [NSView] = Theme.Radius.all.map { name, value in
            let view = tile(raised: false)
            view.layer?.cornerRadius = min(value, 32)
            view.layer?.borderWidth = Theme.Size.hairline
            view.layer?.borderColor = Theme.Color.borderStrong.cgColor
            return NSStackView.vertical([view, caption("--radius-\(name)")], spacing: Theme.Space.s2)
        }
        let shadows: [NSView] = Theme.Shadow.all.map { name, shadow in
            let view = tile(raised: true)
            shadow.apply(to: view.layer!)
            return NSStackView.vertical([view, caption("--shadow-\(name)")], spacing: Theme.Space.s2)
        }
        return block("04", "Radius and elevation", "形", [
            specimen("Radius", [row(radii, spacing: Theme.Space.s8)]),
            specimen("Shadow (floating layers only)", [row(shadows, spacing: Theme.Space.s8)]),
        ])
    }

    private func motion() -> NSView {
        let play = UButton("Play", size: .sm) { [weak self] in self?.playMotion() }
        var rows: [NSView] = [row([play, UIText.body("Respects reduced motion.", color: Theme.Color.textMuted, wraps: false)])]
        for (name, _) in Theme.Motion.easings {
            let label = caption("--ease-\(name)")
            label.widthAnchor.constraint(equalToConstant: 160).isActive = true
            let track = NSView()
            track.wantsLayer = true
            track.layer?.backgroundColor = Theme.Color.surfaceSunken.cgColor
            track.layer?.borderWidth = Theme.Size.hairline
            track.layer?.borderColor = Theme.Color.borderSubtle.cgColor
            track.translatesAutoresizingMaskIntoConstraints = false
            track.widthAnchor.constraint(equalToConstant: 300).isActive = true
            track.heightAnchor.constraint(equalToConstant: 20).isActive = true
            let dot = NSView(frame: NSRect(x: 4, y: 4, width: 12, height: 12))
            dot.wantsLayer = true
            dot.layer?.backgroundColor = Theme.Color.info.cgColor
            track.addSubview(dot)
            motionDots.append(dot)
            rows.append(row([label, track], spacing: Theme.Space.s4))
        }
        rows.append(UIText.body("Durations: " + Theme.Motion.durationNames.map { "--duration-\($0)" }.joined(separator: " · "),
                                size: Theme.TextSize.small, color: Theme.Color.textMuted, wraps: false))
        return block("05", "Motion", "動", rows)
    }

    private func playMotion() {
        motionMoved.toggle()
        for (dot, (_, curve)) in zip(motionDots, Theme.Motion.easings) {
            let from = dot.layer!.position
            let to = CGPoint(x: motionMoved ? 4 + 280 + 6 : 4 + 6, y: from.y)
            let animation = CABasicAnimation(keyPath: "position")
            animation.fromValue = from
            animation.toValue = to
            animation.duration = Theme.Motion.slow
            animation.timingFunction = curve
            dot.layer?.position = to
            dot.layer?.add(animation, forKey: "move")
        }
    }

    private func components() -> NSView {
        let mark = UIText.label(UIText.attributed("殻", family: .display, size: Theme.TextSize.bodyLG, color: Theme.Color.accent))
        let brandText = UIText.label(UIText.attributed("Unshell", family: .sans, size: Theme.TextSize.bodyLG,
                                                       color: Theme.Color.textStrong))
        let topBar = TopBar(
            brand: row([mark, brandText], spacing: Theme.Space.s2),
            nav: [("workspaces", "Workspaces"), ("agents", "Agents"), ("automation", "Automation")],
            active: "workspaces",
            actions: [Badge("v0.1.0", tone: .success, dot: true), UButton("Docs", size: .sm),
                      UButton("New", variant: .primary, size: .sm)]
        )

        let disabled = UButton("Disabled")
        disabled.isEnabled = false
        let buttons = specimen("Button", [
            row([UButton("Install", variant: .primary), UButton("Source"), UButton("Cancel", variant: .ghost),
                 UButton("Delete", variant: .danger), disabled]),
            row([UButton("Small", variant: .primary, size: .sm), UButton("Medium", variant: .primary, size: .md),
                 UButton("Large", variant: .primary, size: .lg)]),
        ])

        let badges = specimen("Badge", [row([
            Badge("neutral"), Badge("1977", tone: .accent, dot: true), Badge("syncing", tone: .info, dot: true),
            Badge("clean", tone: .success, dot: true), Badge("2 changes", tone: .warning, dot: true),
            Badge("failed", tone: .danger, dot: true),
        ], spacing: Theme.Space.s2)])

        let nameField = Field(label: "Workspace name", placeholder: "unshell", hint: "Lowercase, no spaces.")
        let repoField = Field(label: "Repository", value: "git@gitlab.com:me/repo", error: "Repository not reachable.")
        let fields = NSStackView.horizontal([nameField, repoField], spacing: Theme.Space.s6, alignment: .top)
        nameField.widthAnchor.constraint(equalToConstant: 320).isActive = true
        repoField.widthAnchor.constraint(equalToConstant: 320).isActive = true
        let offSwitch = USwitch("Disabled", isOn: false)
        offSwitch.isEnabled = false
        let fieldSpecimen = specimen("Field and switch", [
            fields, row([USwitch("Run agents on save", isOn: true), offSwitch], spacing: Theme.Space.s8),
        ])

        let inline = specimen("Inline", [row([
            UIText.body("Read the", wraps: false), TextLink("workspace manual"),
            UIText.body(", or press", wraps: false), Kbd("⌘"), Kbd("K"),
            UIText.body("to jump anywhere.", wraps: false),
        ], spacing: Theme.Space.s1)])

        let spec = SpecList([
            Spec(label: "Workspace", value: "unshell", note: "~/Projects/personal"),
            Spec(label: "Branch", value: "feat/unshell-mac"),
            Spec(label: "Agent", value: "idle"),
        ])
        let stats = StatGrid([("12", "Repos"), ("48", "Trees"), ("3", "Agents"), ("7", "Jobs")])
        let specRow = NSStackView.horizontal([spec, stats], spacing: Theme.Space.s8, alignment: .top)
        spec.widthAnchor.constraint(equalToConstant: 420).isActive = true
        stats.widthAnchor.constraint(equalToConstant: 420).isActive = true

        let frame = specimen("Frame", [Frame(caption: "00 // Preview", content: Display("Everything, already installed.", size: .md))])

        let features = FeatureGrid([
            Feature(glyph: "換", title: "Change anything.", body: "Swap tools per workspace without touching the others."),
            Feature(glyph: "家", title: "One home.", body: "Repos, trees and knowledge live side by side."),
            Feature(glyph: "人", title: "Nobody works alone.", body: "Agents share the same environment and history."),
        ])

        let accordion = Accordion([
            .init(id: "what", title: "What is Unshell?", content: "A development environment for people and agents."),
            .init(id: "where", title: "Where does my data live?", content: "On your machine, inside each workspace."),
            .init(id: "agents", title: "Which agents can I run?", content: "Any agent that speaks the harness protocol."),
        ], defaultOpen: "what")

        let topBarSpecimen = specimen("Top bar", [topBar])
        let featureSpecimen = specimen("Feature grid", [features])
        let accordionSpecimen = specimen("Accordion", [accordion])
        let result = block("06", "Components", "部", [
            topBarSpecimen, buttons, badges, fieldSpecimen, inline, specimen("Spec list and stats", [specRow]),
            frame, featureSpecimen, accordionSpecimen,
        ])
        for (container, child) in [(topBarSpecimen, topBar as NSView), (featureSpecimen, features), (accordionSpecimen, accordion)] {
            child.widthAnchor.constraint(equalTo: container.widthAnchor).isActive = true
        }
        return result
    }
}
#endif

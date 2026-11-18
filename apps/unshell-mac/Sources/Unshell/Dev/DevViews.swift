#if DEBUG
import AppKit

/// Registry of development-only views, mirroring renderer/dev/views.ts.
/// Register new dev views here; order is the sidebar order.
enum DevViews {
    struct Entry {
        let id: String
        let label: String
        let make: () -> NSView
        /// Views that manage their own scrolling (code viewer, terminals) fill
        /// the content area instead of sitting in a scroll view.
        var scrolls = true
    }

    static let all: [Entry] = [
        Entry(id: "design-system", label: "Design system", make: { DesignSystemView() }),
        Entry(id: "code-viewer", label: "Code viewer", make: { CodeViewerDevView() }, scrolls: false),
        Entry(id: "terminal", label: "Terminal playground", make: { TerminalPlaygroundView() }, scrolls: false),
    ]

    static func make(_ id: String) -> NSView? {
        all.first { $0.id == id }?.make()
    }
}

/// Canvas background with film grain on top, as body/body::after in tokens.css.
final class DevContainer: NSView {
    let content: NSView

    init(content: NSView) {
        self.content = content
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = Theme.Color.canvas.cgColor
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        let grain = GrainOverlay()
        addSubview(grain)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: leadingAnchor),
            content.trailingAnchor.constraint(equalTo: trailingAnchor),
            content.topAnchor.constraint(equalTo: topAnchor),
            content.bottomAnchor.constraint(equalTo: bottomAnchor),
            grain.leadingAnchor.constraint(equalTo: leadingAnchor),
            grain.trailingAnchor.constraint(equalTo: trailingAnchor),
            grain.topAnchor.constraint(equalTo: topAnchor),
            grain.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not used") }

    override var isFlipped: Bool { true }

    func fittingHeight(width: CGFloat) -> CGFloat {
        let constraint = content.widthAnchor.constraint(equalToConstant: width)
        constraint.isActive = true
        defer { constraint.isActive = false }
        return max(200, content.fittingSize.height)
    }
}
#endif

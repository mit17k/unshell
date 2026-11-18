import AppKit
import CodeEditTextView
import UnshellCode

/// Read-only code viewer. Port of renderer/code/CodeViewer.tsx, built for large
/// files and long lines:
/// - CodeEditTextView keeps a line tree and lays out only the visible lines, so
///   lines do not wrap and the view scrolls horizontally (wrapping is a toggle).
/// - tree-sitter parses on a background queue; highlights are computed per
///   8K-character chunk, only for chunks near the viewport, off the main thread.
/// - Styles are applied to the text storage in one editing batch per chunk; the
///   layout manager re-typesets only the affected lines. Fonts carry italic
///   and bold, as in the Electron viewer.
/// - An optional `SemanticTokenProvider` (an LSP client) is layered on top.
final class CodeViewerView: NSView {
    static let chunkSize = 8 * 1024
    static let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
    static let lineHeight: CGFloat = 22 // 13 pt at 1.7, as code.css
    static let gutterWidth: CGFloat = 56

    let filename: String?
    let language: CodeLanguage?
    private let text: String
    private let nsText: NSString
    private let semanticProvider: SemanticTokenProvider?

    let scrollView = NSScrollView()
    let textView: TextView
    private let gutter = LineNumberGutter()
    private let renderDelegate = ClippedLineRenderDelegate()
    private let queue = DispatchQueue(label: "dev.unshell.code-highlight", qos: .userInitiated)
    private var highlighter: SyntaxHighlighter?
    private var lineStarts: [Int] = [0]
    private var requested = Set<Int>()
    private var semanticTokens: [SemanticToken] = []
    private var attributeCache: [TokenStyle: [NSAttributedString.Key: Any]] = [:]
    private var scheduled = false

    /// Called on the main thread after each chunk's styles are applied.
    var onChunkHighlighted: ((Int) -> Void)?
    private(set) var parseSeconds: TimeInterval?

    var wrapLines: Bool {
        get { textView.wrapLines }
        set {
            textView.wrapLines = newValue
            scrollView.hasHorizontalScroller = !newValue
            textView.updateFrameIfNeeded()
            gutter.needsDisplay = true
        }
    }

    init(text: String, language: CodeLanguage?, filename: String? = nil, wrapLines: Bool = false,
         semanticProvider: SemanticTokenProvider? = nil) {
        // A final newline is a file convention, not an extra empty line to show.
        let body = text.hasSuffix("\n") ? String(text.dropLast()) : text
        self.text = body
        self.nsText = body as NSString
        self.language = language
        self.filename = filename
        self.semanticProvider = semanticProvider

        let natural = ceil(Self.font.ascender - Self.font.descender + Self.font.leading)
        // Created empty: TextView lays out every line it has when it is not yet in
        // a scroll view (one view per line fragment), so the text goes in after
        // it is the scroll view's document view.
        textView = TextView(
            string: "",
            font: Self.font,
            textColor: Theme.Palette.fgDark,
            lineHeightMultiplier: Self.lineHeight / natural,
            wrapLines: wrapLines,
            isEditable: false,
            isSelectable: true,
            letterSpacing: 1.0
        )
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        layer?.backgroundColor = Theme.Color.surface.cgColor
        layer?.borderWidth = Theme.Size.hairline
        layer?.borderColor = Theme.Color.borderSubtle.cgColor
        build(wrapLines: wrapLines)
        load()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not used") }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: Layout

    private func build(wrapLines: Bool) {
        let header = NSView()
        header.wantsLayer = true
        header.layer?.backgroundColor = Theme.Color.canvas.cgColor
        header.translatesAutoresizingMaskIntoConstraints = false
        textView.layoutManager.renderDelegate = renderDelegate
        scrollView.documentView = textView
        textView.setText(text)
        let file = UIText.mono(filename ?? "untitled", size: Theme.TextSize.small, color: Theme.Color.text)
        let meta = Eyebrow("\(language?.id ?? "plain") · \(textView.layoutManager.lineCount) lines")
        header.addSubview(file)
        header.addSubview(meta)
        let rule = Hairline()

        textView.edgeInsets = HorizontalEdgeInsets(left: Theme.Space.s2, right: Theme.Space.s6)
        textView.overscrollAmount = 0
        textView.selectionManager.selectionBackgroundColor = Theme.Color.selection
        textView.selectionManager.highlightSelectedLine = false
        textView.selectionManager.insertionPointColor = .clear

        scrollView.drawsBackground = true
        scrollView.backgroundColor = Theme.Color.surface
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = !wrapLines
        scrollView.autohidesScrollers = true
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.contentInsets = NSEdgeInsets(top: Theme.Space.s4, left: 0, bottom: Theme.Space.s4, right: 0)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        gutter.translatesAutoresizingMaskIntoConstraints = false
        gutter.textView = textView
        gutter.scrollView = scrollView

        for view in [header, rule, gutter, scrollView] { addSubview(view) }
        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: leadingAnchor),
            header.trailingAnchor.constraint(equalTo: trailingAnchor),
            header.topAnchor.constraint(equalTo: topAnchor),
            header.heightAnchor.constraint(equalToConstant: Theme.Size.controlMD),
            file.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: Theme.Space.s4),
            file.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            meta.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -Theme.Space.s4),
            meta.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            rule.leadingAnchor.constraint(equalTo: leadingAnchor),
            rule.trailingAnchor.constraint(equalTo: trailingAnchor),
            rule.topAnchor.constraint(equalTo: header.bottomAnchor),
            gutter.leadingAnchor.constraint(equalTo: leadingAnchor),
            gutter.widthAnchor.constraint(equalToConstant: Self.gutterWidth),
            gutter.topAnchor.constraint(equalTo: rule.bottomAnchor),
            gutter.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: gutter.trailingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: rule.bottomAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        // CodeEditTextView lays out lines for the viewport it is told about.
        scrollView.contentView.postsBoundsChangedNotifications = true
        scrollView.postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(viewportChanged),
                                               name: NSView.boundsDidChangeNotification, object: scrollView.contentView)
        NotificationCenter.default.addObserver(self, selector: #selector(sizeChanged),
                                               name: NSView.frameDidChangeNotification, object: scrollView)
    }

    override func layout() {
        super.layout()
        textView.updateFrameIfNeeded()
    }

    // MARK: Loading

    private func load() {
        guard let language else { return }
        let queriesDirectory = CodeViewerView.queriesDirectory
        let body = text
        let source = nsText
        queue.async { [weak self] in
            let starts = SemanticTokens.lineStarts(of: source)
            do {
                let highlighter = try SyntaxHighlighter(text: body, language: language, queriesDirectory: queriesDirectory)
                let seconds = try highlighter.parse()
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.lineStarts = starts
                    self.highlighter = highlighter
                    self.parseSeconds = seconds
                    self.scheduleHighlight()
                }
            } catch {
                GhosttyRuntime.log.error("code viewer: \(String(describing: error), privacy: .public)")
            }
        }

        if let semanticProvider {
            Task { [weak self] in
                guard let tokens = try? await semanticProvider.provide(code: body, language: language) else { return }
                await MainActor.run {
                    guard let self else { return }
                    self.semanticTokens = tokens
                    // Re-style everything already shown with the semantic layer.
                    self.requested.removeAll()
                    self.scheduleHighlight()
                }
            }
        }
    }

    /// Bundled queries (Contents/Resources/TreeSitter) or, for a bare binary,
    /// UNSHELL_QUERIES_DIR.
    static var queriesDirectory: URL {
        if let override = ProcessInfo.processInfo.environment["UNSHELL_QUERIES_DIR"] {
            return URL(fileURLWithPath: override)
        }
        return Bundle.main.resourceURL!.appendingPathComponent("TreeSitter")
    }

    // MARK: Viewport highlighting

    @objc private func viewportChanged() {
        textView.updatedViewport(scrollView.documentVisibleRect)
        gutter.needsDisplay = true
        scheduleHighlight()
    }

    @objc private func sizeChanged() {
        textView.updateFrameIfNeeded()
        gutter.needsDisplay = true
        scheduleHighlight()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        scheduleHighlight()
    }

    /// Coalesces viewport changes into one highlight pass per run-loop turn.
    private func scheduleHighlight() {
        guard !scheduled else { return }
        scheduled = true
        DispatchQueue.main.async { [weak self] in
            self?.scheduled = false
            self?.highlightVisibleChunks()
        }
    }

    /// The UTF-16 range of the lines currently on screen.
    func visibleCharacterRange() -> NSRange? {
        textView.visibleTextRange
    }

    private func highlightVisibleChunks() {
        guard let highlighter, let visible = visibleCharacterRange(), nsText.length > 0 else { return }
        let first = max(0, visible.location / Self.chunkSize - 1)
        let last = min((nsText.length - 1) / Self.chunkSize, NSMaxRange(visible) / Self.chunkSize + 1)
        guard first <= last else { return }
        let semantic = semanticTokens
        let starts = lineStarts
        for chunk in first...last where !requested.contains(chunk) {
            requested.insert(chunk)
            let range = NSIntersectionRange(NSRange(location: chunk * Self.chunkSize, length: Self.chunkSize),
                                            NSRange(location: 0, length: nsText.length))
            queue.async { [weak self] in
                guard var runs = try? highlighter.runs(in: range) else { return }
                if !semantic.isEmpty {
                    runs = SemanticTokens.apply(semantic, to: runs, lineStarts: starts)
                        .compactMap { run in
                            let clipped = NSIntersectionRange(run.range, range)
                            return clipped.length > 0 ? StyledRun(range: clipped, style: run.style,
                                                                  semanticType: run.semanticType) : nil
                        }
                }
                DispatchQueue.main.async { self?.apply(runs, chunk: chunk) }
            }
        }
    }

    private func apply(_ runs: [StyledRun], chunk: Int) {
        guard let storage = textView.textStorage, !runs.isEmpty else {
            onChunkHighlighted?(chunk)
            return
        }
        storage.beginEditing()
        for run in runs where NSMaxRange(run.range) <= storage.length {
            storage.addAttributes(attributes(run.style), range: run.range)
        }
        storage.endEditing()
        onChunkHighlighted?(chunk)
    }

    private func attributes(_ style: TokenStyle) -> [NSAttributedString.Key: Any] {
        if let cached = attributeCache[style] { return cached }
        var font = Self.font
        if style.italic { font = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask) }
        if style.bold { font = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask) }
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: NSColor(hex: style.color), .font: font]
        attributeCache[style] = attributes
        return attributes
    }
}

/// Line numbers beside the text view, drawn for the visible lines only from
/// CodeEditTextView's line tree (index, y position and height per line).
final class LineNumberGutter: NSView {
    weak var textView: TextView?
    weak var scrollView: NSScrollView?
    private let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
        .foregroundColor: Theme.Palette.gutter,
    ]

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        Theme.Color.surface.setFill()
        dirtyRect.intersection(bounds).fill()
        guard let textView, let scrollView else { return }
        let visible = scrollView.documentVisibleRect
        // Document y (top-down) → gutter y: the clip view's origin includes the top inset.
        let offset = -visible.minY
        for line in textView.layoutManager.lineStorage.linesStartingAt(max(0, visible.minY), until: visible.maxY) {
            let label = "\(line.index + 1)" as NSString
            let size = label.size(withAttributes: attributes)
            let y = line.yPos + offset + (CodeViewerView.lineHeight - size.height) / 2
            label.draw(at: NSPoint(x: bounds.width - Theme.Space.s4 - size.width, y: y), withAttributes: attributes)
        }
    }
}

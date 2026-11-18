import AppKit
import UnshellCode

/// Read-only code viewer. Port of renderer/code/CodeViewer.tsx, built for large
/// files:
/// - TextKit 2 lays out only the viewport.
/// - tree-sitter parses on a background queue; highlights are computed per
///   8K-character chunk, only for chunks near the viewport, off the main thread.
/// - Colours go in as TextKit 2 rendering attributes, so the text storage (and
///   layout) never changes after load.
/// - An optional `SemanticTokenProvider` (an LSP client) is layered on top.
final class CodeViewerView: NSView {
    static let chunkSize = 8 * 1024

    let filename: String?
    let language: CodeLanguage?
    private let text: String
    private let nsText: NSString
    private let semanticProvider: SemanticTokenProvider?

    let scrollView = NSScrollView()
    let textView: NSTextView
    private let ruler: LineNumberRuler
    private let queue = DispatchQueue(label: "dev.unshell.code-highlight", qos: .userInitiated)
    private var highlighter: SyntaxHighlighter?
    private var lineStarts: [Int] = [0]
    private var requested = Set<Int>()
    private var semanticTokens: [SemanticToken] = []
    private var colorCache: [UInt32: NSColor] = [:]
    private var scheduled = false

    /// Called on the main thread after each chunk's colours are applied.
    var onChunkHighlighted: ((Int) -> Void)?
    private(set) var parseSeconds: TimeInterval?

    init(text: String, language: CodeLanguage?, filename: String? = nil, semanticProvider: SemanticTokenProvider? = nil) {
        // A final newline is a file convention, not an extra empty line to show.
        let body = text.hasSuffix("\n") ? String(text.dropLast()) : text
        self.text = body
        self.nsText = body as NSString
        self.language = language
        self.filename = filename
        self.semanticProvider = semanticProvider
        textView = NSTextView(usingTextLayoutManager: true)
        ruler = LineNumberRuler(textView: textView)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        layer?.backgroundColor = Theme.Color.surface.cgColor
        layer?.borderWidth = Theme.Size.hairline
        layer?.borderColor = Theme.Color.borderSubtle.cgColor
        build()
        load()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not used") }

    deinit { NotificationCenter.default.removeObserver(self) }

    static let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
    static let lineHeight: CGFloat = 22 // 13 pt at 1.7, as code.css
    /// Finite: a layer-backed view sized to .greatestFiniteMagnitude stops Core
    /// Animation rendering the whole window.
    static let maxWidth: CGFloat = 100_000

    // MARK: Layout

    private func build() {
        let header = NSView()
        header.wantsLayer = true
        header.layer?.backgroundColor = Theme.Color.canvas.cgColor
        header.translatesAutoresizingMaskIntoConstraints = false
        let file = UIText.mono(filename ?? "untitled", size: Theme.TextSize.small, color: Theme.Color.text)
        let lineCount = nsText.length == 0 ? 0 : nsText.components(separatedBy: "\n").count
        let meta = Eyebrow("\(language?.id ?? "plain") · \(lineCount) lines")
        header.addSubview(file)
        header.addSubview(meta)
        let rule = Hairline()

        scrollView.drawsBackground = true
        scrollView.backgroundColor = Theme.Color.surface
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = textView
        scrollView.verticalRulerView = ruler
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true

        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.drawsBackground = true
        textView.backgroundColor = Theme.Color.surface
        textView.selectedTextAttributes = [.backgroundColor: Theme.Color.selection]
        textView.textContainerInset = NSSize(width: 0, height: Theme.Space.s4)
        textView.isVerticallyResizable = true
        // Soft wrap at the viewport width. TextKit 2 lays out only the viewport
        // when lines wrap; a non-wrapping (horizontally resizable) text view makes
        // it lay out everything above the viewport on every scroll, which on a
        // 50k-line file costs ~30 ms a frame (see docs/electron-parity.md).
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineFragmentPadding = Theme.Space.s4
        textView.maxSize = NSSize(width: Self.maxWidth, height: .greatestFiniteMagnitude)

        for view in [header, rule, scrollView] { addSubview(view) }
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
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: rule.bottomAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(viewportChanged),
                                               name: NSView.boundsDidChangeNotification, object: scrollView.contentView)
    }

    // MARK: Loading

    private func load() {
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = Self.lineHeight
        paragraph.maximumLineHeight = Self.lineHeight
        paragraph.tabStops = []
        paragraph.defaultTabInterval = Self.font.maximumAdvancement.width * 2 // tab-size: 2
        let attributes: [NSAttributedString.Key: Any] = [
            .font: Self.font,
            .foregroundColor: Theme.Palette.fgDark,
            .paragraphStyle: paragraph,
            .baselineOffset: 3,
        ]
        textView.typingAttributes = attributes
        // One attribute run for the whole document: plain text paints at once.
        textView.textContentStorage?.textStorage?.setAttributedString(NSAttributedString(string: text, attributes: attributes))

        let source = nsText
        queue.async { [weak self] in
            let starts = SemanticTokens.lineStarts(of: source)
            DispatchQueue.main.async {
                self?.lineStarts = starts
                self?.ruler.lineStarts = starts
            }
        }

        guard let language else { return }
        let queriesDirectory = CodeViewerView.queriesDirectory
        let body = text
        queue.async { [weak self] in
            do {
                let highlighter = try SyntaxHighlighter(text: body, language: language, queriesDirectory: queriesDirectory)
                let seconds = try highlighter.parse()
                DispatchQueue.main.async {
                    guard let self else { return }
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
                    // Re-colour everything already shown with the semantic layer.
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

    /// The UTF-16 range TextKit is currently showing.
    func visibleCharacterRange() -> NSRange? {
        guard let layoutManager = textView.textLayoutManager,
              let content = layoutManager.textContentManager,
              let viewport = layoutManager.textViewportLayoutController.viewportRange
        else { return nil }
        let start = content.offset(from: content.documentRange.location, to: viewport.location)
        let end = content.offset(from: content.documentRange.location, to: viewport.endLocation)
        return NSRange(location: start, length: max(0, end - start))
    }

    private func highlightVisibleChunks() {
        guard let highlighter, let visible = visibleCharacterRange() else { return }
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
                        .filter { NSIntersectionRange($0.range, range).length > 0 }
                }
                DispatchQueue.main.async { self?.apply(runs, chunk: chunk) }
            }
        }
    }

    private func apply(_ runs: [StyledRun], chunk: Int) {
        guard let layoutManager = textView.textLayoutManager, let content = layoutManager.textContentManager else { return }
        let documentStart = content.documentRange.location
        guard let chunkStart = content.location(documentStart, offsetBy: chunk * Self.chunkSize) else { return }
        let base = chunk * Self.chunkSize
        for run in runs {
            guard let start = content.location(chunkStart, offsetBy: run.range.location - base),
                  let end = content.location(start, offsetBy: run.range.length),
                  let range = NSTextRange(location: start, end: end)
            else { continue }
            layoutManager.setRenderingAttributes([.foregroundColor: color(run.style.color)], for: range)
        }
        onChunkHighlighted?(chunk)
    }

    private func color(_ hex: UInt32) -> NSColor {
        if let cached = colorCache[hex] { return cached }
        let color = NSColor(hex: hex)
        colorCache[hex] = color
        return color
    }
}

/// Line numbers for a TextKit 2 text view: draws a label beside each laid-out
/// paragraph in the viewport. Line numbers come from precomputed line starts.
final class LineNumberRuler: NSRulerView {
    private weak var textView: NSTextView?
    var lineStarts: [Int] = [0] { didSet { needsDisplay = true } }
    private let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
        .foregroundColor: Theme.Palette.gutter,
    ]

    init(textView: NSTextView) {
        self.textView = textView
        super.init(scrollView: nil, orientation: .verticalRuler)
        clientView = textView
        ruleThickness = 56
    }

    @available(*, unavailable)
    required init(coder: NSCoder) { fatalError("not used") }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        // Clamp to our bounds: inside a layer-backed scroll view the dirty rect
        // can extend past the ruler, and filling it paints over the window.
        let rect = dirtyRect.intersection(bounds)
        Theme.Color.surface.setFill()
        rect.fill()
        drawHashMarksAndLabels(in: rect)
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView, let layoutManager = textView.textLayoutManager,
              let content = layoutManager.textContentManager,
              let viewport = layoutManager.textViewportLayoutController.viewportRange
        else { return }
        let documentStart = content.documentRange.location
        let origin = convert(NSPoint.zero, from: textView)
        layoutManager.enumerateTextLayoutFragments(from: viewport.location, options: []) { fragment in
            let offset = content.offset(from: documentStart, to: fragment.rangeInElement.location)
            let line = lineIndex(for: offset) + 1
            let frame = fragment.layoutFragmentFrame
            let y = origin.y + frame.minY + textView.textContainerInset.height
            if y > rect.maxY { return false }
            let label = "\(line)" as NSString
            let size = label.size(withAttributes: attributes)
            label.draw(at: NSPoint(x: ruleThickness - Theme.Space.s4 - size.width,
                                   y: y + (CodeViewerView.lineHeight - size.height) / 2), withAttributes: attributes)
            return fragment.rangeInElement.endLocation.compare(viewport.endLocation) == .orderedAscending
        }
    }

    private func lineIndex(for offset: Int) -> Int {
        var low = 0, high = lineStarts.count - 1
        while low < high {
            let mid = (low + high + 1) / 2
            if lineStarts[mid] <= offset { low = mid } else { high = mid - 1 }
        }
        return low
    }
}

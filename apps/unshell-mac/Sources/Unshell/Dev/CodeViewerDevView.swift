#if DEBUG
import AppKit
import QuartzCore
import UnshellCode

/// Sample files and the generated large file used by the dev code viewer.
/// Port of the former Electron renderer/dev/samples.ts (the files themselves live in Resources/Samples).
enum CodeSamples {
    static let files: [String: String] = [
        "typescript": "workspace.ts", "tsx": "AgentCard.tsx", "javascript": "queue.js", "python": "indexer.py",
        "go": "server.go", "rust": "tree.rs", "java": "Scheduler.java", "kotlin": "Projects.kt",
        "swift": "Settings.swift", "c": "ring.c", "cpp": "cache.cpp", "csharp": "Notifier.cs", "ruby": "hooks.rb",
        "php": "Router.php", "elixir": "supervisor.ex", "shellscript": "bootstrap.sh", "sql": "report.sql",
        "html": "index.html", "css": "styles.css", "json": "workspace.json", "yaml": "pipeline.yaml",
        "toml": "Cargo.toml", "markdown": "README.md", "dockerfile": "Dockerfile", "nix": "devshell.nix",
    ]

    static var directory: URL {
        if let override = ProcessInfo.processInfo.environment["UNSHELL_SAMPLES_DIR"] {
            return URL(fileURLWithPath: override)
        }
        return Bundle.main.resourceURL!.appendingPathComponent("Samples")
    }

    static func text(for languageId: String) -> String? {
        guard let file = files[languageId] else { return nil }
        return try? String(contentsOf: directory.appendingPathComponent(file), encoding: .utf8)
    }

    /// Minified-style JavaScript: `lines` lines of about `width` characters each,
    /// built from the JavaScript sample with whitespace collapsed.
    static func minified(lines: Int, width: Int) -> String {
        let sample = (text(for: "javascript") ?? "let a=1;")
            .split(whereSeparator: { $0 == "\n" }).map { $0.trimmingCharacters(in: .whitespaces) }
            // Line comments would swallow the rest of a joined line.
            .filter { !$0.hasPrefix("//") && !$0.hasPrefix("/*") && !$0.hasPrefix("*") }
            .joined(separator: " ")
        var line = ""
        while line.count < width { line += sample + ";" }
        return Array(repeating: line, count: lines).joined(separator: "\n") + "\n"
    }

    /// A TypeScript file of `lines` lines, built by repeating the sample.
    static func large(lines: Int) -> String {
        let sample = (text(for: "typescript") ?? "const x = 1;\n").split(separator: "\n", omittingEmptySubsequences: false)
        var out: [Substring] = []
        out.reserveCapacity(lines)
        while out.count < lines { out.append(contentsOf: sample.prefix(lines - out.count)) }
        return out.joined(separator: "\n") + "\n"
    }
}

/// Dev › Code viewer: a language picker over the 25 samples, plus a generated
/// 50,000-line TypeScript file. Port of the former Electron renderer/dev/views/CodeViewerView.tsx.
final class CodeViewerDevView: NSView {
    private let host = NSView()
    private weak var viewer: CodeViewerView?
    private var labels: [String: NSTextField] = [:]
    private static let largeId = "large"
    private static let longId = "long"

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        translatesAutoresizingMaskIntoConstraints = false

        let wrapSwitch = USwitch("Wrap lines", isOn: false) { [weak self] on in self?.viewer?.wrapLines = on }
        let list = NSStackView.vertical([wrapSwitch, Eyebrow("\(CodeLanguages.all.count) languages")], spacing: 0)
        list.setCustomSpacing(Theme.Space.s5, after: wrapSwitch)
        list.setCustomSpacing(Theme.Space.s3, after: list.arrangedSubviews[1])
        let entries = CodeLanguages.all.map { ($0.id, $0.label) }
            + [(Self.largeId, "Large file · 50k lines"), (Self.longId, "Long lines · 12k chars")]
        for (id, label) in entries {
            let field = UIText.label(UIText.attributed(label, family: .sans, size: Theme.TextSize.body,
                                                       color: Theme.Color.textSecondary))
            labels[id] = field
            let item = ClickableStack(views: [field]) { [weak self] in self?.show(id) }
            item.edgeInsets = NSEdgeInsets(top: 3, left: 0, bottom: 3, right: 0)
            list.addArrangedSubview(item)
        }
        let listScroll = NSScrollView()
        listScroll.drawsBackground = false
        listScroll.hasVerticalScroller = true
        let listDoc = FlippedView()
        listDoc.translatesAutoresizingMaskIntoConstraints = false
        listDoc.addSubview(list)
        listScroll.documentView = listDoc
        listScroll.translatesAutoresizingMaskIntoConstraints = false
        host.translatesAutoresizingMaskIntoConstraints = false
        addSubview(listScroll)
        addSubview(host)
        NSLayoutConstraint.activate([
            listScroll.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Theme.Space.s6),
            listScroll.topAnchor.constraint(equalTo: topAnchor, constant: Theme.Space.s6),
            listScroll.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Theme.Space.s6),
            listScroll.widthAnchor.constraint(equalToConstant: 200),
            listDoc.widthAnchor.constraint(equalTo: listScroll.contentView.widthAnchor),
            list.leadingAnchor.constraint(equalTo: listDoc.leadingAnchor),
            list.trailingAnchor.constraint(equalTo: listDoc.trailingAnchor),
            list.topAnchor.constraint(equalTo: listDoc.topAnchor),
            list.bottomAnchor.constraint(equalTo: listDoc.bottomAnchor),
            host.leadingAnchor.constraint(equalTo: listScroll.trailingAnchor, constant: Theme.Space.s6),
            host.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Theme.Space.s6),
            host.topAnchor.constraint(equalTo: topAnchor, constant: Theme.Space.s6),
            host.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Theme.Space.s6),
        ])
        show(ProcessInfo.processInfo.environment["UNSHELL_CODE_LANGUAGE"] ?? "typescript")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not used") }

    private func show(_ id: String) {
        for (key, label) in labels {
            let name = key == Self.largeId ? "Large file · 50k lines"
                : key == Self.longId ? "Long lines · 12k chars" : (CodeLanguages.find(key)?.label ?? key)
            label.attributedStringValue = UIText.attributed(name, family: .sans, size: Theme.TextSize.body,
                                                            color: key == id ? Theme.Color.textStrong : Theme.Color.textSecondary)
        }
        host.subviews.forEach { $0.removeFromSuperview() }
        let viewer: CodeViewerView
        if id == Self.longId {
            viewer = CodeViewerView(text: CodeSamples.minified(lines: 100, width: 12_000),
                                    language: CodeLanguages.find("javascript"), filename: "minified.js")
        } else if id == Self.largeId {
            viewer = CodeViewerView(text: CodeSamples.large(lines: 50_000), language: CodeLanguages.find("typescript"),
                                    filename: "large.ts")
        } else {
            guard let language = CodeLanguages.find(id), let text = CodeSamples.text(for: id) else { return }
            viewer = CodeViewerView(text: text, language: language, filename: CodeSamples.files[id])
        }
        self.viewer = viewer
        host.addSubview(viewer)
        NSLayoutConstraint.activate([
            viewer.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            viewer.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            viewer.topAnchor.constraint(equalTo: host.topAnchor),
            viewer.bottomAnchor.constraint(equalTo: host.bottomAnchor),
        ])
    }
}

/// `UNSHELL_CODE_BENCH=<lines>`: opens a generated TypeScript file of that many
/// lines, measures time to first paint, time to first highlighted paint, parse
/// time, jump-to-position latency and display-linked scrolling, prints JSON
/// to stdout and exits. Debug builds only (use an optimized Debug build for
/// representative numbers: `just mac-code-bench`).
final class CodeViewerBenchmark: NSObject {
    private static var current: CodeViewerBenchmark?
    private var window: NSWindow!
    private var viewer: CodeViewerView!
    private var results: [String: Any] = [:]
    private var link: CADisplayLink?
    private var ticks: [CFTimeInterval] = []
    private var tickWork: [Double] = []
    private var frameDuration: CFTimeInterval = 1.0 / 60
    private let scrollFrames = 600

    static func runIfRequested() {
        guard let raw = ProcessInfo.processInfo.environment["UNSHELL_CODE_BENCH"], let lines = Int(raw) else { return }
        let bench = CodeViewerBenchmark()
        current = bench
        bench.start(lines: lines)
    }

    private func ms(_ seconds: CFTimeInterval) -> Double { (seconds * 100_000).rounded() / 100 }

    private var longLines = false

    private func start(lines: Int) {
        let env = ProcessInfo.processInfo.environment
        longLines = env["UNSHELL_CODE_BENCH_KIND"] == "long"
        let wrap = env["UNSHELL_CODE_WRAP"] != nil
        let text = longLines ? CodeSamples.minified(lines: lines, width: 12_000) : CodeSamples.large(lines: lines)
        let language = CodeLanguages.find(longLines ? "javascript" : "typescript")
        results["kind"] = longLines ? "long-lines (12k chars)" : "typescript"
        results["wrap"] = wrap
        results["lines"] = lines
        results["characters"] = (text as NSString).length

        window = NSWindow(contentRect: NSRect(x: 80, y: 80, width: 1200, height: 900),
                          styleMask: [.titled, .resizable], backing: .buffered, defer: false)
        window.title = "Code viewer benchmark"
        window.appearance = NSAppearance(named: .darkAqua)
        window.makeKeyAndOrderFront(nil)

        let t0 = CACurrentMediaTime()
        viewer = CodeViewerView(text: text, language: language, filename: longLines ? "minified.js" : "large.ts",
                                wrapLines: wrap)
        window.contentView = viewer
        window.layoutIfNeeded()
        window.displayIfNeeded()
        let firstPaint = CACurrentMediaTime() - t0
        results["firstPaintMs"] = ms(firstPaint)

        var highlightedOnce = false
        viewer.onChunkHighlighted = { [weak self] _ in
            guard let self, !highlightedOnce else { return }
            highlightedOnce = true
            self.window.displayIfNeeded()
            self.results["firstHighlightedPaintMs"] = self.ms(CACurrentMediaTime() - t0)
            self.results["parseMs"] = self.ms(self.viewer.parseSeconds ?? 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.jumps() }
        }
    }

    /// Jump to 25/50/75/100% and time layout + paint + highlight of the new viewport.
    private func jumps(_ fractions: [Double] = [0.25, 0.5, 0.75, 1.0], timings: [[String: Double]] = []) {
        guard let fraction = fractions.first else {
            results["jumps"] = timings
            scrollToTop()
            return
        }
        let clip = viewer.scrollView.contentView
        let docHeight = viewer.textView.frame.height
        let start = CACurrentMediaTime()
        clip.scroll(to: NSPoint(x: 0, y: max(0, docHeight * fraction - clip.bounds.height)))
        viewer.scrollView.reflectScrolledClipView(clip)
        window.layoutIfNeeded()
        window.displayIfNeeded()
        let paint = CACurrentMediaTime() - start
        var done = false
        // If the new viewport's chunks were already highlighted, no callback comes.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard !done else { return }
            self?.viewer.onChunkHighlighted?(-1)
        }
        viewer.onChunkHighlighted = { [weak self] _ in
            guard let self, !done else { return }
            done = true
            self.window.displayIfNeeded()
            let highlighted = CACurrentMediaTime() - start
            self.viewer.onChunkHighlighted = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.jumps(Array(fractions.dropFirst()),
                           timings: timings + [["at": fraction, "paintMs": self.ms(paint), "highlightedMs": self.ms(highlighted)]])
            }
        }
    }

    private func scrollToTop() {
        viewer.scrollView.contentView.scroll(to: .zero)
        viewer.scrollView.reflectScrolledClipView(viewer.scrollView.contentView)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.startScrolling() }
    }

    /// Display-linked scroll, 3 lines per frame, as fast trackpad scrolling.
    private func startScrolling() {
        let link = viewer.displayLink(target: self, selector: #selector(tick(_:)))
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    /// Second phase for long lines: scroll right, 60 pt a frame.
    private var horizontal = false
    private var verticalResult: [String: Any] = [:]

    @objc private func tick(_ link: CADisplayLink) {
        frameDuration = link.duration > 0 ? link.duration : frameDuration
        ticks.append(link.timestamp)
        let start = CACurrentMediaTime()
        let clip = viewer.scrollView.contentView
        var origin = clip.bounds.origin
        if horizontal { origin.x += 60 } else { origin.y += CodeViewerView.lineHeight * 3 }
        clip.scroll(to: origin)
        viewer.scrollView.reflectScrolledClipView(clip)
        window.layoutIfNeeded()
        window.displayIfNeeded()
        tickWork.append(CACurrentMediaTime() - start)
        if ticks.count >= scrollFrames { finish() }
    }

    private func percentile(_ values: [Double], _ p: Double) -> Double {
        let sorted = values.sorted()
        guard !sorted.isEmpty else { return 0 }
        return sorted[min(sorted.count - 1, Int(Double(sorted.count - 1) * p))]
    }

    private func finish() {
        link?.invalidate()
        let intervals = zip(ticks.dropFirst(), ticks).map { $0 - $1 }
        let dropped = intervals.reduce(0) { $0 + max(0, Int(($1 / frameDuration).rounded()) - 1) }
        let summary: [String: Any] = [
            "frames": ticks.count,
            "refreshHz": (1 / frameDuration).rounded(),
            "frameIntervalAvgMs": ms(intervals.reduce(0, +) / Double(max(1, intervals.count))),
            "frameIntervalP95Ms": ms(percentile(intervals, 0.95)),
            "frameIntervalMaxMs": ms(intervals.max() ?? 0),
            "droppedFrames": dropped,
            "mainThreadWorkAvgMs": ms(tickWork.reduce(0, +) / Double(max(1, tickWork.count))),
            "mainThreadWorkP95Ms": ms(percentile(tickWork, 0.95)),
            "mainThreadWorkMaxMs": ms(tickWork.max() ?? 0),
            (horizontal ? "pointsScrolledRight" : "linesScrolled"): ticks.count * (horizontal ? 60 : 3),
        ]
        if longLines && !horizontal {
            // Then scroll right along the long lines, from the top.
            results["scroll"] = summary
            horizontal = true
            ticks.removeAll()
            tickWork.removeAll()
            viewer.scrollView.contentView.scroll(to: .zero)
            viewer.scrollView.reflectScrolledClipView(viewer.scrollView.contentView)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.startScrolling() }
            return
        }
        results[horizontal ? "scrollHorizontal" : "scroll"] = summary
        let data = try! JSONSerialization.data(withJSONObject: results, options: [.prettyPrinted, .sortedKeys])
        FileHandle.standardOutput.write(data)
        FileHandle.standardOutput.write("\n".data(using: .utf8)!)
        exit(0)
    }
}
#endif

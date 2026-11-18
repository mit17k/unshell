import Foundation
import SwiftTreeSitter

/// One coloured run of text. Ranges are UTF-16 (NSString) offsets.
public struct StyledRun: Equatable, Sendable {
    public var range: NSRange
    public var style: TokenStyle
    /// Set when an LSP semantic token overrode the grammar colour.
    public var semanticType: String?

    public init(range: NSRange, style: TokenStyle, semanticType: String? = nil) {
        self.range = range
        self.style = style
        self.semanticType = semanticType
    }
}

public enum HighlighterError: Error, CustomStringConvertible {
    case parserRejectedLanguage(String)
    case missingQueries(URL)
    case query(String, Error)

    public var description: String {
        switch self {
        case .parserRejectedLanguage(let id): return "tree-sitter rejected the \(id) grammar (ABI mismatch?)"
        case .missingQueries(let url): return "no highlight queries at \(url.path)"
        case .query(let id, let error): return "\(id) highlight query failed to compile: \(error)"
        }
    }
}

/// Compiled highlight queries are shared by every document of a language.
final class QueryCache: @unchecked Sendable {
    static let shared = QueryCache()
    private let lock = NSLock()
    private var queries: [String: Query] = [:]

    func query(for language: CodeLanguage, queriesDirectory: URL) throws -> Query {
        lock.lock()
        defer { lock.unlock() }
        if let cached = queries[language.grammar] { return cached }
        let url = queriesDirectory.appendingPathComponent(language.grammar).appendingPathComponent("queries/highlights.scm")
        guard let data = FileManager.default.contents(atPath: url.path) else { throw HighlighterError.missingQueries(url) }
        do {
            let query = try Query(language: language.treeSitterLanguage, data: data)
            queries[language.grammar] = query
            return query
        } catch {
            throw HighlighterError.query(language.id, error)
        }
    }
}

/// Parses one document and answers highlight requests for ranges of it.
///
/// Not thread-safe: confine an instance to one serial queue. Parsing a large
/// file and querying ranges are both meant to run off the main thread; only
/// the resulting `StyledRun`s cross back.
public final class SyntaxHighlighter {
    public let language: CodeLanguage
    public let text: NSString
    private let query: Query
    private let theme: CaptureTheme
    private var tree: MutableTree?

    public init(text: String, language: CodeLanguage, queriesDirectory: URL, theme: CaptureTheme = .tokyoNight) throws {
        self.language = language
        self.text = text as NSString
        self.theme = theme
        query = try QueryCache.shared.query(for: language, queriesDirectory: queriesDirectory)
    }

    /// Parses the whole document. Cheap to call again; the tree is reused.
    @discardableResult
    public func parse() throws -> TimeInterval {
        if tree != nil { return 0 }
        let start = Date()
        let parser = Parser()
        do {
            try parser.setLanguage(language.treeSitterLanguage)
        } catch {
            throw HighlighterError.parserRejectedLanguage(language.id)
        }
        tree = parser.parse(text as String)
        return Date().timeIntervalSince(start)
    }

    /// Styled runs covering `range`, non-overlapping and sorted. Text with no
    /// capture gets no run (the view's default colour applies).
    public func runs(in range: NSRange) throws -> [StyledRun] {
        try parse()
        guard let tree, range.length > 0 else { return [] }
        let clamped = NSIntersectionRange(range, NSRange(location: 0, length: text.length))
        guard clamped.length > 0 else { return [] }

        let cursor = query.execute(in: tree)
        cursor.setRange(clamped)
        let source = text
        let context = Predicate.Context(textProvider: { nsRange, _ in
            NSMaxRange(nsRange) <= source.length ? source.substring(with: nsRange) : nil
        })

        // Collect captures, then paint outer-to-inner so nested captures win, and
        // lower pattern indices win ties (tree-sitter's precedence rule).
        struct Span { let range: NSRange; let pattern: Int; let style: TokenStyle }
        var spans: [Span] = []
        while let match = cursor.next() {
            guard match.allowed(in: context) else { continue }
            for capture in match.captures {
                guard let name = capture.name, let style = theme.style(for: name) else { continue }
                let span = NSIntersectionRange(capture.range, clamped)
                guard span.length > 0 else { continue }
                spans.append(Span(range: span, pattern: capture.patternIndex, style: style))
            }
        }
        spans.sort { lhs, rhs in
            lhs.range.length != rhs.range.length ? lhs.range.length > rhs.range.length : lhs.pattern > rhs.pattern
        }

        var painted = [Int32](repeating: -1, count: clamped.length)
        var styles: [TokenStyle] = []
        var styleIndex: [TokenStyle: Int32] = [:]
        for span in spans {
            let index: Int32
            if let existing = styleIndex[span.style] {
                index = existing
            } else {
                index = Int32(styles.count)
                styles.append(span.style)
                styleIndex[span.style] = index
            }
            let start = span.range.location - clamped.location
            for offset in start..<(start + span.range.length) { painted[offset] = index }
        }

        var runs: [StyledRun] = []
        var runStart = 0
        while runStart < painted.count {
            let value = painted[runStart]
            var runEnd = runStart + 1
            while runEnd < painted.count, painted[runEnd] == value { runEnd += 1 }
            if value >= 0 {
                runs.append(StyledRun(range: NSRange(location: clamped.location + runStart, length: runEnd - runStart),
                                      style: styles[Int(value)]))
            }
            runStart = runEnd
        }
        return runs
    }
}

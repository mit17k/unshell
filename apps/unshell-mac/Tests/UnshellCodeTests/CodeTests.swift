import Foundation
import Testing
@testable import UnshellCode

private let macDir = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
private let queries = macDir.appendingPathComponent("Vendor/TreeSitterGrammars")
private let samples = macDir.appendingPathComponent("Resources/Samples")

/// Sample file per language id, as in renderer/dev/samples.ts.
let sampleFiles: [String: String] = [
    "typescript": "workspace.ts", "tsx": "AgentCard.tsx", "javascript": "queue.js", "python": "indexer.py",
    "go": "server.go", "rust": "tree.rs", "java": "Scheduler.java", "kotlin": "Projects.kt",
    "swift": "Settings.swift", "c": "ring.c", "cpp": "cache.cpp", "csharp": "Notifier.cs", "ruby": "hooks.rb",
    "php": "Router.php", "elixir": "supervisor.ex", "shellscript": "bootstrap.sh", "sql": "report.sql",
    "html": "index.html", "css": "styles.css", "json": "workspace.json", "yaml": "pipeline.yaml",
    "toml": "Cargo.toml", "markdown": "README.md", "dockerfile": "Dockerfile", "nix": "devshell.nix",
]

@Suite struct Languages {
    @Test func registryHasTheElectronLanguages() {
        #expect(CodeLanguages.all.count == 25)
        #expect(Set(CodeLanguages.all.map(\.id)) == Set(sampleFiles.keys))
    }

    @Test func detectsFromFileNames() {
        #expect(CodeLanguages.detect(fileName: "src/main.rs")?.id == "rust")
        #expect(CodeLanguages.detect(fileName: "Dockerfile")?.id == "dockerfile")
        #expect(CodeLanguages.detect(fileName: "deploy.sh")?.id == "shellscript")
        #expect(CodeLanguages.detect(fileName: "notes") == nil)
    }

    @Test(arguments: CodeLanguages.all)
    func everySampleHighlights(language: CodeLanguage) throws {
        let file = try #require(sampleFiles[language.id])
        let text = try String(contentsOf: samples.appendingPathComponent(file), encoding: .utf8)
        let highlighter = try SyntaxHighlighter(text: text, language: language, queriesDirectory: queries)
        let runs = try highlighter.runs(in: NSRange(location: 0, length: (text as NSString).length))
        // Every sample has several distinct token colours.
        #expect(Set(runs.map(\.style.color)).count >= 3, "\(language.id) produced \(runs.count) runs")
        // Runs are sorted and never overlap.
        for (previous, next) in zip(runs, runs.dropFirst()) {
            #expect(NSMaxRange(previous.range) <= next.range.location)
        }
    }
}

@Suite struct Highlighting {
    let language = CodeLanguages.find("python")!

    @Test func rangeLimitsTheRuns() throws {
        let text = "def first():\n    return 1\n\ndef second():\n    return 'two'\n"
        let highlighter = try SyntaxHighlighter(text: text, language: language, queriesDirectory: queries)
        let secondLine = (text as NSString).range(of: "def second")
        let window = NSRange(location: secondLine.location, length: (text as NSString).length - secondLine.location)
        let runs = try highlighter.runs(in: window)
        #expect(!runs.isEmpty)
        #expect(runs.allSatisfy { $0.range.location >= window.location })
    }

    @Test func nestedCapturesWin() throws {
        let text = "x = 'a\\nb'\n"
        let highlighter = try SyntaxHighlighter(text: text, language: language, queriesDirectory: queries)
        let runs = try highlighter.runs(in: NSRange(location: 0, length: (text as NSString).length))
        let escape = (text as NSString).range(of: "\\n")
        let string = CaptureTheme.tokyoNight.style(for: "string")!.color
        let escapeRun = try #require(runs.first { NSLocationInRange(escape.location, $0.range) })
        #expect(escapeRun.style.color != string)
    }

    @Test func highlightsInsideAVeryLongLine() throws {
        // Minified-style JavaScript: one 20,000-character line, queried mid-line
        // as the viewer does for a horizontally scrolled chunk.
        let statement = "const value=compute(1,'two',[3]);"
        let line = String(repeating: statement, count: 20_000 / statement.count + 1)
        let highlighter = try SyntaxHighlighter(text: line, language: CodeLanguages.find("javascript")!,
                                                queriesDirectory: queries)
        let window = NSRange(location: 10_000, length: 8_192)
        let runs = try highlighter.runs(in: window)
        #expect(runs.allSatisfy { NSLocationInRange($0.range.location, window) })
        let colors = Set(runs.map(\.style.color))
        #expect(colors.contains(CaptureTheme.tokyoNight.style(for: "string")!.color))
        #expect(colors.contains(CaptureTheme.tokyoNight.style(for: "keyword")!.color))
    }

    @Test func captureNamesFallBackToTheirParent() {
        let theme = CaptureTheme.tokyoNight
        #expect(theme.style(for: "function.method.call") == theme.style(for: "function.method"))
        #expect(theme.style(for: "nonsense") == nil)
    }
}

/// Ports of renderer/code/semantic.test.ts.
@Suite struct Semantic {
    @Test func decodesRelativeTuples() {
        let legend = SemanticLegend(tokenTypes: ["variable", "parameter"], tokenModifiers: ["readonly", "defaultLibrary"])
        let tokens = SemanticTokens.decode([0, 4, 3, 1, 0, 0, 6, 2, 0, 3, 2, 1, 5, 0, 2], legend: legend)
        #expect(tokens == [
            SemanticToken(line: 0, character: 4, length: 3, type: "parameter"),
            SemanticToken(line: 0, character: 10, length: 2, type: "variable", modifiers: ["readonly", "defaultLibrary"]),
            SemanticToken(line: 2, character: 1, length: 5, type: "variable", modifiers: ["defaultLibrary"]),
        ])
    }

    // "fn(value, other)" with grammar runs fn( / value, other / )
    let runs = [
        StyledRun(range: NSRange(location: 0, length: 3), style: TokenStyle(0x7AA2F7)),
        StyledRun(range: NSRange(location: 3, length: 12), style: TokenStyle(0xC0CAF5)),
        StyledRun(range: NSRange(location: 15, length: 1), style: TokenStyle(0x9ABDF5)),
    ]

    @Test func splitsAGrammarRunAroundASemanticToken() {
        let painted = SemanticTokens.apply([SemanticToken(line: 0, character: 3, length: 5, type: "parameter")],
                                           to: runs, lineStarts: [0])
        #expect(painted.map { [$0.range.location, $0.range.length, Int($0.style.color)] } == [
            [0, 3, 0x7AA2F7],
            [3, 5, 0xE0AF68],
            [8, 7, 0xC0CAF5],
            [15, 1, 0x9ABDF5],
        ])
        #expect(painted[1].semanticType == "parameter")
    }

    @Test func prefersTypeModifierColourAndIgnoresUnknownTypes() {
        let painted = SemanticTokens.apply([
            SemanticToken(line: 0, character: 10, length: 5, type: "variable", modifiers: ["defaultLibrary"]),
            SemanticToken(line: 0, character: 0, length: 2, type: "function"),
        ], to: runs, lineStarts: [0])
        #expect(painted.first { $0.range.location == 10 }?.style.color == 0x2AC3DE)
        #expect(painted[0].style.color == 0x7AA2F7)
    }

    @Test func lineStartsCountUTF16() {
        #expect(SemanticTokens.lineStarts(of: "ab\ncd\n\nef" as NSString) == [0, 3, 6, 7])
    }
}

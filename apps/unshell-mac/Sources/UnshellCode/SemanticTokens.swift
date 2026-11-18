import Foundation

/// A decoded LSP semantic token (textDocument/semanticTokens). Positions are
/// zero-based line and UTF-16 character, as the protocol defines them.
/// Port of renderer/code/semantic.ts.
public struct SemanticToken: Equatable, Sendable {
    public var line: Int
    public var character: Int
    public var length: Int
    public var type: String
    public var modifiers: [String]

    public init(line: Int, character: Int, length: Int, type: String, modifiers: [String] = []) {
        self.line = line
        self.character = character
        self.length = length
        self.type = type
        self.modifiers = modifiers
    }
}

/// Anything that can supply semantic tokens, usually a language server client.
/// Its tokens are layered over the tree-sitter captures.
public protocol SemanticTokenProvider: Sendable {
    func provide(code: String, language: CodeLanguage) async throws -> [SemanticToken]
}

public struct SemanticLegend: Sendable {
    public var tokenTypes: [String]
    public var tokenModifiers: [String]

    public init(tokenTypes: [String], tokenModifiers: [String]) {
        self.tokenTypes = tokenTypes
        self.tokenModifiers = tokenModifiers
    }
}

public enum SemanticTokens {
    /// Decodes the LSP wire format (relative five-integer tuples) using a legend.
    public static func decode(_ data: [Int], legend: SemanticLegend) -> [SemanticToken] {
        var result: [SemanticToken] = []
        var line = 0
        var character = 0
        var index = 0
        while index + 4 < data.count {
            let deltaLine = data[index], deltaStart = data[index + 1], length = data[index + 2]
            let typeIndex = data[index + 3], modifierBits = data[index + 4]
            line += deltaLine
            character = deltaLine == 0 ? character + deltaStart : deltaStart
            let modifiers = legend.tokenModifiers.enumerated()
                .filter { modifierBits & (1 << $0.offset) != 0 }
                .map(\.element)
            let type = typeIndex < legend.tokenTypes.count ? legend.tokenTypes[typeIndex] : "unknown"
            result.append(SemanticToken(line: line, character: character, length: length, type: type, modifiers: modifiers))
            index += 5
        }
        return result
    }

    /// Tokyo Night's semantic colours, matching its VS Code theme.
    public static let tokyoNightColors: [String: UInt32] = [
        "parameter": 0xE0AF68,
        "property": 0x73DACA,
        "property.readonly": 0x73DACA,
        "enumMember": 0xFF9E64,
        "variable.defaultLibrary": 0x2AC3DE,
        "variable.readonly": 0xC0CAF5,
        "class.defaultLibrary": 0x2AC3DE,
        "type.defaultLibrary": 0x2AC3DE,
        "namespace": 0x7DCFFF,
        "typeParameter": 0x2AC3DE,
        "macro": 0x7DCFFF,
        "selfKeyword": 0xF7768E,
    ]

    static func color(for token: SemanticToken, colors: [String: UInt32]) -> UInt32? {
        for modifier in token.modifiers {
            if let color = colors["\(token.type).\(modifier)"] { return color }
        }
        return colors[token.type]
    }

    /// UTF-16 offset of the start of every line, for converting LSP positions.
    public static func lineStarts(of text: NSString) -> [Int] {
        var starts = [0]
        var index = 0
        let length = text.length
        while index < length {
            let range = text.lineRange(for: NSRange(location: index, length: 0))
            index = NSMaxRange(range)
            if index < length || (index == length && length > 0 && text.character(at: length - 1) == 10) {
                starts.append(index)
            }
            if range.length == 0 { break }
        }
        return starts
    }

    /// Layers semantic tokens over grammar runs, splitting runs where a semantic
    /// token starts or ends. Types with no colour in the map are ignored, and a
    /// semantic token over unstyled text adds a run of its own.
    public static func apply(
        _ semantic: [SemanticToken],
        to runs: [StyledRun],
        lineStarts: [Int],
        colors: [String: UInt32] = tokyoNightColors
    ) -> [StyledRun] {
        var result = runs
        for token in semantic {
            guard token.line < lineStarts.count, let color = color(for: token, colors: colors) else { continue }
            let start = lineStarts[token.line] + token.character
            let end = start + token.length
            var next: [StyledRun] = []
            var covered = start
            for run in result {
                let runStart = run.range.location, runEnd = NSMaxRange(run.range)
                if runEnd <= start || runStart >= end {
                    next.append(run)
                    continue
                }
                if runStart < start {
                    next.append(StyledRun(range: NSRange(location: runStart, length: start - runStart), style: run.style,
                                          semanticType: run.semanticType))
                }
                let overlapStart = max(start, runStart), overlapEnd = min(end, runEnd)
                if overlapStart > covered {
                    next.append(StyledRun(range: NSRange(location: covered, length: overlapStart - covered),
                                          style: TokenStyle(color), semanticType: token.type))
                }
                var style = run.style
                style.color = color
                next.append(StyledRun(range: NSRange(location: overlapStart, length: overlapEnd - overlapStart),
                                      style: style, semanticType: token.type))
                covered = overlapEnd
                if runEnd > end {
                    next.append(StyledRun(range: NSRange(location: end, length: runEnd - end), style: run.style,
                                          semanticType: run.semanticType))
                }
            }
            if covered < end {
                next.append(StyledRun(range: NSRange(location: covered, length: end - covered),
                                      style: TokenStyle(color), semanticType: token.type))
            }
            result = next.sorted { $0.range.location < $1.range.location }
        }
        return result
    }
}

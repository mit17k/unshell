import Foundation

/// Colour and font traits for one token. Colours are 0xRRGGBB so this module
/// stays free of AppKit; the app turns them into NSColor.
public struct TokenStyle: Hashable, Sendable {
    public var color: UInt32
    public var italic: Bool
    public var bold: Bool

    public init(_ color: UInt32, italic: Bool = false, bold: Bool = false) {
        self.color = color
        self.italic = italic
        self.bold = bold
    }
}

/// Maps tree-sitter capture names (`@function.method`, `@string.special`...)
/// to styles. A name falls back to its parent (`function.method` → `function`),
/// so grammars with finer captures still get coloured.
public struct CaptureTheme: Sendable {
    public var styles: [String: TokenStyle]

    public init(styles: [String: TokenStyle]) {
        self.styles = styles
    }

    public func style(for capture: String) -> TokenStyle? {
        var name = Substring(capture)
        while true {
            if let style = styles[String(name)] { return style }
            guard let dot = name.lastIndex(of: ".") else { return nil }
            name = name[..<dot]
        }
    }

    /// Tokyo Night (night), matching the VS Code theme the Electron viewer used
    /// through Shiki.
    public static let tokyoNight: CaptureTheme = {
        let fg: UInt32 = 0xC0CAF5
        let magenta: UInt32 = 0xBB9AF7
        let blue: UInt32 = 0x7AA2F7
        let cyan: UInt32 = 0x7DCFFF
        let blue1: UInt32 = 0x2AC3DE
        let teal: UInt32 = 0x73DACA
        let green: UInt32 = 0x9ECE6A
        let yellow: UInt32 = 0xE0AF68
        let orange: UInt32 = 0xFF9E64
        let red: UInt32 = 0xF7768E
        let blue5: UInt32 = 0x89DDFF
        let bracket: UInt32 = 0x9ABDF5
        let comment: UInt32 = 0x565F89
        let fgDark: UInt32 = 0xA9B1D6

        return CaptureTheme(styles: [
            "comment": TokenStyle(comment, italic: true),
            "keyword": TokenStyle(magenta),
            "keyword.function": TokenStyle(magenta),
            "keyword.return": TokenStyle(magenta),
            "keyword.operator": TokenStyle(blue5),
            "keyword.import": TokenStyle(blue5),
            "keyword.directive": TokenStyle(blue5),
            "include": TokenStyle(blue5),
            "conditional": TokenStyle(magenta),
            "repeat": TokenStyle(magenta),
            "exception": TokenStyle(magenta),
            "storageclass": TokenStyle(magenta),
            "preproc": TokenStyle(blue5),
            "operator": TokenStyle(blue5),
            "punctuation": TokenStyle(blue5),
            "punctuation.bracket": TokenStyle(bracket),
            "punctuation.delimiter": TokenStyle(blue5),
            "punctuation.special": TokenStyle(blue5),

            "string": TokenStyle(green),
            "string.regex": TokenStyle(cyan),
            "string.regexp": TokenStyle(cyan),
            "string.escape": TokenStyle(blue5),
            "string.special": TokenStyle(cyan),
            "string.special.key": TokenStyle(teal),
            "string.special.symbol": TokenStyle(teal),
            "escape": TokenStyle(blue5),
            "character": TokenStyle(green),
            "number": TokenStyle(orange),
            "float": TokenStyle(orange),
            "boolean": TokenStyle(orange),
            "constant": TokenStyle(orange),
            "constant.builtin": TokenStyle(orange),

            "function": TokenStyle(blue),
            "function.builtin": TokenStyle(blue1),
            "function.macro": TokenStyle(cyan),
            "function.method": TokenStyle(blue),
            "method": TokenStyle(blue),
            "constructor": TokenStyle(blue1),
            "type": TokenStyle(blue1),
            "type.builtin": TokenStyle(blue1),
            "type.definition": TokenStyle(blue1),
            "module": TokenStyle(cyan),
            "namespace": TokenStyle(cyan),

            "variable": TokenStyle(fg),
            "variable.builtin": TokenStyle(red),
            "variable.parameter": TokenStyle(yellow),
            "variable.member": TokenStyle(teal),
            "parameter": TokenStyle(yellow),
            "property": TokenStyle(teal),
            "field": TokenStyle(teal),
            "label": TokenStyle(blue),
            "attribute": TokenStyle(magenta),
            "tag": TokenStyle(red),
            "tag.attribute": TokenStyle(magenta),
            "tag.delimiter": TokenStyle(blue5),
            "embedded": TokenStyle(fg),

            // Markup (Markdown)
            "markup.heading": TokenStyle(blue, bold: true),
            "text.title": TokenStyle(blue, bold: true),
            "markup.strong": TokenStyle(orange, bold: true),
            "markup.italic": TokenStyle(magenta, italic: true),
            "markup.link": TokenStyle(teal),
            "markup.link.url": TokenStyle(cyan),
            "text.uri": TokenStyle(cyan),
            "markup.raw": TokenStyle(teal),
            "text.literal": TokenStyle(teal),
            "markup.list": TokenStyle(orange),
            "markup.quote": TokenStyle(fgDark, italic: true),
            "text.reference": TokenStyle(teal),
        ])
    }()
}

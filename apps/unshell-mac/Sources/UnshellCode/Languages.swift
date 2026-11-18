import Foundation
import SwiftTreeSitter
import Grammar_bash
import Grammar_c
import Grammar_cpp
import Grammar_csharp
import Grammar_css
import Grammar_dockerfile
import Grammar_elixir
import Grammar_go
import Grammar_html
import Grammar_java
import Grammar_javascript
import Grammar_json
import Grammar_kotlin
import Grammar_markdown
import Grammar_nix
import Grammar_php
import Grammar_python
import Grammar_ruby
import Grammar_rust
import Grammar_sql
import Grammar_swift
import Grammar_toml
import Grammar_tsx
import Grammar_typescript
import Grammar_yaml

/// A language the code viewer can highlight. Ids match the Electron viewer's
/// Shiki ids (renderer/code/languages.ts) so samples and callers carry over.
public struct CodeLanguage: Sendable, Hashable {
    /// Shiki-compatible id, e.g. "shellscript".
    public let id: String
    public let label: String
    /// Directory name under Vendor/TreeSitterGrammars and the bundled queries.
    public let grammar: String
    public let fileExtensions: [String]
    public let fileNames: [String]

    let entry: @Sendable () -> OpaquePointer?

    public static func == (lhs: CodeLanguage, rhs: CodeLanguage) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }

    public var treeSitterLanguage: Language { Language(language: entry()!) }
}

public enum CodeLanguages {
    private static func language(
        _ id: String, _ label: String, _ grammar: String, _ extensions: [String], names: [String] = [],
        _ entry: @escaping @Sendable () -> OpaquePointer?
    ) -> CodeLanguage {
        CodeLanguage(id: id, label: label, grammar: grammar, fileExtensions: extensions, fileNames: names, entry: entry)
    }

    /// The 25 languages, in the Electron viewer's order.
    public static let all: [CodeLanguage] = {
        var list: [CodeLanguage] = []
        list.append(language("typescript", "TypeScript", "typescript", ["ts", "mts", "cts"]) { tree_sitter_typescript() })
        list.append(language("tsx", "TSX", "tsx", ["tsx"]) { tree_sitter_tsx() })
        list.append(language("javascript", "JavaScript", "javascript", ["js", "mjs", "cjs", "jsx"]) { tree_sitter_javascript() })
        list.append(language("python", "Python", "python", ["py", "pyi"]) { tree_sitter_python() })
        list.append(language("go", "Go", "go", ["go"]) { tree_sitter_go() })
        list.append(language("rust", "Rust", "rust", ["rs"]) { tree_sitter_rust() })
        list.append(language("java", "Java", "java", ["java"]) { tree_sitter_java() })
        list.append(language("kotlin", "Kotlin", "kotlin", ["kt", "kts"]) { tree_sitter_kotlin() })
        list.append(language("swift", "Swift", "swift", ["swift"]) { tree_sitter_swift() })
        list.append(language("c", "C", "c", ["c", "h"]) { tree_sitter_c() })
        list.append(language("cpp", "C++", "cpp", ["cpp", "cc", "cxx", "hpp", "hh", "hxx"]) { tree_sitter_cpp() })
        list.append(language("csharp", "C#", "csharp", ["cs"]) { tree_sitter_c_sharp() })
        list.append(language("ruby", "Ruby", "ruby", ["rb"], names: ["Gemfile", "Rakefile"]) { tree_sitter_ruby() })
        list.append(language("php", "PHP", "php", ["php"]) { tree_sitter_php() })
        list.append(language("elixir", "Elixir", "elixir", ["ex", "exs"]) { tree_sitter_elixir() })
        list.append(language("shellscript", "Shell", "bash", ["sh", "bash", "zsh"]) { tree_sitter_bash() })
        list.append(language("sql", "SQL", "sql", ["sql"]) { tree_sitter_sql() })
        list.append(language("html", "HTML", "html", ["html", "htm"]) { tree_sitter_html() })
        list.append(language("css", "CSS", "css", ["css"]) { tree_sitter_css() })
        list.append(language("json", "JSON", "json", ["json"]) { tree_sitter_json() })
        list.append(language("yaml", "YAML", "yaml", ["yaml", "yml"]) { tree_sitter_yaml() })
        list.append(language("toml", "TOML", "toml", ["toml"]) { tree_sitter_toml() })
        list.append(language("markdown", "Markdown", "markdown", ["md", "markdown"]) { tree_sitter_markdown() })
        list.append(language("dockerfile", "Dockerfile", "dockerfile", [], names: ["Dockerfile", "Containerfile"]) { tree_sitter_dockerfile() })
        list.append(language("nix", "Nix", "nix", ["nix"]) { tree_sitter_nix() })
        return list
    }()

    public static func find(_ id: String) -> CodeLanguage? {
        all.first { $0.id == id }
    }

    /// Picks a language from a file name (extension or well-known name).
    public static func detect(fileName: String) -> CodeLanguage? {
        let name = (fileName as NSString).lastPathComponent
        if let match = all.first(where: { $0.fileNames.contains(name) }) { return match }
        let ext = (name as NSString).pathExtension.lowercased()
        guard !ext.isEmpty else { return nil }
        return all.first { $0.fileExtensions.contains(ext) }
    }
}

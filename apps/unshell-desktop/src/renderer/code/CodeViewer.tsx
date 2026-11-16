import { useEffect, useState } from "react";
import { plainLines, tokenize } from "./highlighter.js";
import { applySemanticTokens, type SemanticTokenProvider } from "./semantic.js";
import type { CodeLine } from "./tokens.js";
import "./code.css";

export interface CodeViewerProps {
  code: string;
  lang: string;
  filename?: string;
  /** Optional LSP-backed provider; its tokens are layered on the grammar. */
  semanticTokens?: SemanticTokenProvider;
}

export function CodeViewer({
  code: source,
  lang,
  filename,
  semanticTokens,
}: CodeViewerProps) {
  // A final newline is a file convention, not an extra empty line to show.
  const code = source.endsWith("\n") ? source.slice(0, -1) : source;
  const [lines, setLines] = useState<CodeLine[]>(() => plainLines(code));

  useEffect(() => {
    let active = true;
    setLines(plainLines(code));
    void (async () => {
      let next = await tokenize(code, lang);
      if (semanticTokens) {
        try {
          next = applySemanticTokens(
            next,
            await semanticTokens.provide(code, lang),
          );
        } catch {
          // Grammar colours are still correct when the language server fails.
        }
      }
      if (active) setLines(next);
    })();
    return () => {
      active = false;
    };
  }, [code, lang, semanticTokens]);

  return (
    <figure className="code-viewer">
      {filename && (
        <figcaption className="code-viewer-header">
          <span className="code-viewer-file">{filename}</span>
          <span className="u-eyebrow">
            {lang} · {lines.length} lines
          </span>
        </figcaption>
      )}
      <pre className="code-viewer-body" tabIndex={0}>
        <code>
          {lines.map((line, index) => (
            <span key={index} className="code-line">
              <span className="code-gutter" aria-hidden>
                {index + 1}
              </span>
              <span className="code-text">
                {line.map((token) => (
                  <span
                    key={token.column}
                    data-semantic={token.semanticType}
                    style={{
                      color: token.color,
                      fontStyle: token.italic ? "italic" : undefined,
                      fontWeight: token.bold ? "bold" : undefined,
                      textDecoration: token.underline ? "underline" : undefined,
                    }}
                  >
                    {token.content}
                  </span>
                ))}
              </span>
            </span>
          ))}
        </code>
      </pre>
    </figure>
  );
}

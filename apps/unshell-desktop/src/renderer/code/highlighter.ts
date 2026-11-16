import { createHighlighterCore, type HighlighterCore } from "shiki/core";
import { createJavaScriptRegexEngine } from "shiki/engine/javascript";
import { findLanguage } from "./languages.js";
import type { CodeLine } from "./tokens.js";

export const THEME = "tokyo-night";

let highlighter: Promise<HighlighterCore> | undefined;

// The JavaScript regex engine avoids WebAssembly, so the renderer CSP does not
// need 'wasm-unsafe-eval'.
function getHighlighter() {
  highlighter ??= createHighlighterCore({
    themes: [import("shiki/themes/tokyo-night.mjs")],
    langs: [],
    engine: createJavaScriptRegexEngine(),
  });
  return highlighter;
}

const FONT_ITALIC = 1;
const FONT_BOLD = 2;
const FONT_UNDERLINE = 4;

/** Grammar (TextMate) highlighting. Unknown languages come back uncoloured. */
export async function tokenize(
  code: string,
  lang: string,
): Promise<CodeLine[]> {
  const shiki = await getHighlighter();
  const language = findLanguage(lang);
  if (!language) return plainLines(code);
  if (!shiki.getLoadedLanguages().includes(language.id)) {
    await shiki.loadLanguage((await language.load()).default);
  }
  const { tokens } = shiki.codeToTokens(code, {
    lang: language.id,
    theme: THEME,
  });
  return tokens.map((line) => {
    let column = 0;
    return line.map((token) => {
      const style = token.fontStyle ?? 0;
      const result = {
        content: token.content,
        column,
        color: token.color,
        italic: (style & FONT_ITALIC) !== 0,
        bold: (style & FONT_BOLD) !== 0,
        underline: (style & FONT_UNDERLINE) !== 0,
      };
      column += token.content.length;
      return result;
    });
  });
}

export function plainLines(code: string): CodeLine[] {
  return code
    .split("\n")
    .map((content) => (content ? [{ content, column: 0 }] : []));
}

import type { CodeLine, CodeToken } from "./tokens.js";

/**
 * A decoded LSP semantic token (textDocument/semanticTokens). Positions are
 * zero-based line and UTF-16 character, as the protocol defines them.
 */
export interface SemanticToken {
  line: number;
  character: number;
  length: number;
  type: string;
  modifiers?: string[];
}

/** Anything that can supply semantic tokens, usually a language server client. */
export interface SemanticTokenProvider {
  provide(code: string, lang: string): Promise<SemanticToken[]>;
}

/** Decodes the LSP wire format (relative five-integer tuples) using a legend. */
export function decodeSemanticTokens(
  data: number[],
  legend: { tokenTypes: string[]; tokenModifiers: string[] },
): SemanticToken[] {
  const result: SemanticToken[] = [];
  let line = 0;
  let character = 0;
  for (let i = 0; i + 4 < data.length; i += 5) {
    const [deltaLine, deltaStart, length, typeIndex, modifierBits] = data.slice(
      i,
      i + 5,
    ) as [number, number, number, number, number];
    line += deltaLine;
    character = deltaLine === 0 ? character + deltaStart : deltaStart;
    const modifiers = legend.tokenModifiers.filter(
      (_, bit) => modifierBits & (1 << bit),
    );
    result.push({
      line,
      character,
      length,
      type: legend.tokenTypes[typeIndex] ?? "unknown",
      modifiers,
    });
  }
  return result;
}

/** Tokyo Night's semantic colours, matching its VS Code theme. */
export const tokyoNightSemanticColors: Record<string, string> = {
  parameter: "#e0af68",
  property: "#73daca",
  "property.readonly": "#73daca",
  enumMember: "#ff9e64",
  "variable.defaultLibrary": "#2ac3de",
  "variable.readonly": "#c0caf5",
  "class.defaultLibrary": "#2ac3de",
  "type.defaultLibrary": "#2ac3de",
  namespace: "#7dcfff",
  typeParameter: "#2ac3de",
  macro: "#7dcfff",
  selfKeyword: "#f7768e",
};

function colorFor(token: SemanticToken, colors: Record<string, string>) {
  for (const modifier of token.modifiers ?? []) {
    const color = colors[`${token.type}.${modifier}`];
    if (color) return color;
  }
  return colors[token.type];
}

/**
 * Layers semantic tokens over grammar tokens, splitting grammar runs where a
 * semantic token starts or ends. Types with no colour in the map are ignored.
 */
export function applySemanticTokens(
  lines: CodeLine[],
  semantic: SemanticToken[],
  colors: Record<string, string> = tokyoNightSemanticColors,
): CodeLine[] {
  const byLine = new Map<number, SemanticToken[]>();
  for (const token of semantic) {
    const list = byLine.get(token.line) ?? [];
    list.push(token);
    byLine.set(token.line, list);
  }
  return lines.map((line, index) => {
    const overlays = byLine.get(index);
    if (!overlays) return line;
    let result = line;
    for (const overlay of overlays) {
      const color = colorFor(overlay, colors);
      if (color) result = paint(result, overlay, color);
    }
    return result;
  });
}

function paint(
  line: CodeLine,
  overlay: SemanticToken,
  color: string,
): CodeLine {
  const start = overlay.character;
  const end = start + overlay.length;
  const out: CodeToken[] = [];
  for (const token of line) {
    const tokenEnd = token.column + token.content.length;
    if (tokenEnd <= start || token.column >= end) {
      out.push(token);
      continue;
    }
    const cuts = [
      token.column,
      Math.max(start, token.column),
      Math.min(end, tokenEnd),
      tokenEnd,
    ];
    for (let i = 0; i < 3; i++) {
      const from = cuts[i]!;
      const to = cuts[i + 1]!;
      if (to <= from) continue;
      const inside = i === 1;
      out.push({
        ...token,
        content: token.content.slice(from - token.column, to - token.column),
        column: from,
        ...(inside ? { color, semanticType: overlay.type } : {}),
      });
    }
  }
  return out;
}

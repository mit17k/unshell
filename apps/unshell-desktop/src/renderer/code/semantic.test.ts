import { describe, expect, it } from "vitest";
import { applySemanticTokens, decodeSemanticTokens } from "./semantic.js";
import type { CodeLine } from "./tokens.js";

describe("decodeSemanticTokens", () => {
  it("turns relative LSP tuples into absolute positions", () => {
    const legend = {
      tokenTypes: ["variable", "parameter"],
      tokenModifiers: ["readonly", "defaultLibrary"],
    };
    expect(
      decodeSemanticTokens(
        [0, 4, 3, 1, 0, 0, 6, 2, 0, 3, 2, 1, 5, 0, 2],
        legend,
      ),
    ).toEqual([
      { line: 0, character: 4, length: 3, type: "parameter", modifiers: [] },
      {
        line: 0,
        character: 10,
        length: 2,
        type: "variable",
        modifiers: ["readonly", "defaultLibrary"],
      },
      {
        line: 2,
        character: 1,
        length: 5,
        type: "variable",
        modifiers: ["defaultLibrary"],
      },
    ]);
  });
});

describe("applySemanticTokens", () => {
  const line: CodeLine = [
    { content: "fn(", column: 0, color: "#7aa2f7" },
    { content: "value, other", column: 3, color: "#c0caf5" },
    { content: ")", column: 15, color: "#9abdf5" },
  ];

  it("splits a grammar token around a semantic token", () => {
    const [painted] = applySemanticTokens(
      [line],
      [{ line: 0, character: 3, length: 5, type: "parameter" }],
    );
    expect(
      painted?.map((token) => [token.content, token.color, token.column]),
    ).toEqual([
      ["fn(", "#7aa2f7", 0],
      ["value", "#e0af68", 3],
      [", other", "#c0caf5", 8],
      [")", "#9abdf5", 15],
    ]);
  });

  it("prefers a type.modifier colour and ignores unknown types", () => {
    const [painted] = applySemanticTokens(
      [line],
      [
        {
          line: 0,
          character: 10,
          length: 5,
          type: "variable",
          modifiers: ["defaultLibrary"],
        },
        { line: 0, character: 0, length: 2, type: "function" },
      ],
    );
    expect(painted?.find((token) => token.content === "other")?.color).toBe(
      "#2ac3de",
    );
    expect(painted?.[0]?.color).toBe("#7aa2f7");
  });
});

import type { ITheme } from "@xterm/xterm";

/** Tokyo Night (night) ANSI palette, matching the official terminal themes. */
export const tokyoNightTerminal: ITheme = {
  background: "#1a1b26",
  foreground: "#c0caf5",
  cursor: "#c0caf5",
  cursorAccent: "#1a1b26",
  selectionBackground: "#33467c",
  selectionForeground: "#c0caf5",
  black: "#15161e",
  red: "#f7768e",
  green: "#9ece6a",
  yellow: "#e0af68",
  blue: "#7aa2f7",
  magenta: "#bb9af7",
  cyan: "#7dcfff",
  white: "#a9b1d6",
  brightBlack: "#414868",
  brightRed: "#f7768e",
  brightGreen: "#9ece6a",
  brightYellow: "#e0af68",
  brightBlue: "#7aa2f7",
  brightMagenta: "#bb9af7",
  brightCyan: "#7dcfff",
  brightWhite: "#c0caf5",
};

/** Bundled fallback for Nerd Font / Powerline private-use glyphs. */
export const symbolsFont = "Symbols Nerd Font Mono";

// Text uses the first available monospace font; prompt icons and powerline
// glyphs fall through to the bundled symbols font, glyph by glyph.
export const terminalFont = `"SF Mono", "JetBrains Mono", "Cascadia Code", Menlo, Consolas, "${symbolsFont}", monospace`;

# Electron parity

Inventory of everything in `apps/unshell-desktop` (Electron) and the root tooling that refers to it, with the native
macOS equivalent in `apps/unshell-mac`. The Electron app stays until every row below is either done or explicitly
dropped, and removal is approved.

Status values: **done** (native equivalent works), **planned** (scheduled in this migration), **deprecated** (Electron
command still works and warns; native replacement listed), **dropped** (no native equivalent; reason given), **n/a**
(Electron plumbing that disappears with Electron).

## Product surface

The Electron app's production window is empty: everything user-visible lives behind the development-only Dev area.

| Item                                              | What it does                                                                                                                         | Swift equivalent                                                                      | Status                  |
| ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------- | ----------------------- |
| Main window (`main/index.ts`)                     | 1280×860 window, canvas `#16161e`, title "Unshell"; re-created on dock activate                                                      | `TerminalWindowController` (AppKit window, Tokyo Night canvas)                        | done                    |
| External links (`setWindowOpenHandler`)           | `http(s)` links open in the default browser; navigation inside the window is blocked                                                 | `GHOSTTY_ACTION_OPEN_URL` → `NSWorkspace.open`; no web content to navigate            | done                    |
| Terminal (`renderer/terminal/TerminalPane.tsx`)   | xterm.js 6 with WebGL, fit, Unicode 11, web links; 10k scrollback; bar cursor; option-as-meta                                        | libghostty surface (`TerminalSurfaceView`): Metal, PTY and IO thread owned by Ghostty | done                    |
| Terminal theme (`terminal/theme.ts`)              | Tokyo Night ANSI palette, selection `#33467c`                                                                                        | `Resources/unshell-ghostty.conf` (same palette)                                       | done                    |
| Nerd Font symbols (`terminal/fonts/*.woff2`)      | Bundled Symbols Nerd Font for prompt glyphs                                                                                          | libghostty embeds a Nerd Font symbols fallback                                        | done                    |
| Terminal tabs (`dev/views/TerminalView.tsx`)      | Tabs with shell name, "exited" marker, close button, "+ New", renderer and size badges                                               | Dev › Terminal playground                                                             | done                    |
| PTY host (`main/pty-host.ts`, `main/terminal.ts`) | node-pty spawn of `$SHELL -l`, 5 ms output batching, high/low-water flow control with renderer acks, size validation, kill on reload | Ghostty's own PTY, IO thread and renderer backpressure; no IPC hop exists             | n/a                     |
| `TERM_PROGRAM=Unshell`, `TERM=xterm-256color`     | Identifies the terminal to shells                                                                                                    | Ghostty sets `TERM=xterm-ghostty`, `TERM_PROGRAM=ghostty`; Unshell adds `UNSHELL=1`   | done (different values) |
| macOS spawn-helper chmod fix                      | Works around node-pty prebuilds losing the execute bit                                                                               | Not needed without node-pty                                                           | n/a                     |

## Design system

| Item                                              | What it does                                                                     | Swift equivalent                                        | Status |
| ------------------------------------------------- | -------------------------------------------------------------------------------- | ------------------------------------------------------- | ------ |
| `tokens.css` palette (`--tn-*`)                   | 20 Tokyo Night colours                                                           | `Theme.Palette`                                         | done   |
| `tokens.css` semantic colours                     | Surfaces, lines, text, intent, focus, selection, overlay                         | `Theme.swift`                                           | done   |
| `tokens.css` type                                 | Serif display, sans, mono families; 8-step scale; leading, weights, tracking     | `Theme.swift`                                           | done   |
| `tokens.css` spacing, sizing, radii               | 4 px grid, control heights, hairline, square radii                               | `Theme.swift`                                           | done   |
| `tokens.css` elevation                            | Flat surfaces; shadows 1–3 and a focus glow                                      | `Theme.swift`                                           | done   |
| `tokens.css` motion                               | Durations, three easing curves, reduced-motion override                          | `Theme.swift`                                           | done   |
| `tokens.css` layers                               | z-index scale                                                                    | AppKit view and window ordering                         | n/a    |
| Film grain (`body::after` SVG noise)              | 6 % noise over the canvas                                                        | `GrainOverlay` (noise tile generated once, 6 % opacity) | done   |
| `ui/Typography` (Display, Eyebrow, Kbd, TextLink) | Serif display headings, mono uppercase labels, key caps, accent-underlined links | `UI/Typography.swift`                                   | done   |
| `ui/Button`                                       | 4 variants × 3 sizes, mono uppercase, square, pressed nudge                      | `UButton`                                               | done   |
| `ui/Badge`                                        | 6 tones, optional dot                                                            | `Badge`                                                 | done   |
| `ui/Field`                                        | Labelled input with hint and error                                               | `Field`                                                 | done   |
| `ui/Switch`                                       | Square toggle with sliding thumb                                                 | `USwitch`                                               | done   |
| `ui/SectionHeader`                                | "01 TITLE ──── 字" header                                                        | `SectionHeader`                                         | done   |
| `ui/SpecList`                                     | Label, rule, value rows                                                          | `SpecList`                                              | done   |
| `ui/StatGrid`                                     | Hairline grid of big numbers                                                     | `StatGrid`                                              | done   |
| `ui/Frame`                                        | Hairline box with corner brackets and caption                                    | `Frame`                                                 | done   |
| `ui/FeatureGrid`                                  | Glyph, title, body columns                                                       | `FeatureGrid`                                           | done   |
| `ui/Accordion`                                    | Single-open disclosure list                                                      | `Accordion`                                             | done   |
| `ui/TopBar`                                       | Brand, mono nav with accent underline, actions                                   | `TopBar`                                                | done   |
| `ui/cx.ts`                                        | Class-name join helper                                                           | Not needed                                              | n/a    |

## Code viewer

| Item                                             | What it does                                                                                                                                                         | Swift equivalent                                                                                                     | Status |
| ------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- | ------ |
| `code/highlighter.ts` (Shiki 4, JS regex engine) | TextMate grammar highlighting in Tokyo Night, lazy grammar loading                                                                                                   | SwiftTreeSitter 0.25 with vendored grammars (`grammars.tsv`); captures mapped by `CaptureTheme.tokyoNight`           | done   |
| `code/languages.ts`                              | 25 languages (TS, TSX, JS, Python, Go, Rust, Java, Kotlin, Swift, C, C++, C#, Ruby, PHP, Elixir, Shell, SQL, HTML, CSS, JSON, YAML, TOML, Markdown, Dockerfile, Nix) | `CodeLanguages` (same 25 ids, tree-sitter grammars)                                                                  | done   |
| `code/semantic.ts` (`SemanticTokenProvider`)     | LSP semantic token decoding and layering over grammar tokens, Tokyo Night colours                                                                                    | `SemanticTokenProvider` protocol, `SemanticTokens.decode/apply` over capture runs                                    | done   |
| `code/CodeViewer.tsx`                            | Header (file, language, line count), gutter, line hover; renders every line                                                                                          | `CodeViewerView`: CodeEditTextView, no wrap (toggle), viewport-only chunked highlighting off the main thread, gutter | done   |
| `code/semantic.test.ts`                          | Decoding and layering tests                                                                                                                                          | `Tests/UnshellCodeTests` (`just mac-test`), plus all 25 samples                                                      | done   |

## Development area

| Item                                         | What it does                                                                  | Swift equivalent                                                         | Status |
| -------------------------------------------- | ----------------------------------------------------------------------------- | ------------------------------------------------------------------------ | ------ |
| `App.tsx` `import.meta.env.DEV` gate         | Dev tooling exists only in development bundles                                | `#if DEBUG` around `Dev/`                                                | done   |
| `dev/DevTools.tsx` (Dev button)              | Floating toggle for the Dev area                                              | Dev menu (⌥⌘1…), `UNSHELL_DEV_VIEW=<id>`                                 | done   |
| `dev/DevArea.tsx`, `dev/views.ts`            | Registry of dev views with a sidebar; Escape closes                           | `DevWindowController` with `DevViews` registry; Escape closes            | done   |
| `dev/views/DesignSystemView.tsx`             | Specimen: palette, semantic colours, type, spacing, radii, motion, components | Dev › Design system                                                      | done   |
| `dev/views/CodeViewerView.tsx`, `samples.ts` | Language picker over 25 sample files                                          | Dev › Code viewer (samples in `Resources/Samples`, plus a 50k-line file) | done   |
| `dev/views/TerminalView.tsx`                 | Terminal tabs playground                                                      | Dev › Terminal playground                                                | done   |
| `dev/dev.css`                                | Dev area and specimen layout                                                  | AppKit layout in the dev views                                           | done   |

### Code viewer measurements

`just mac-code-bench` (optimized build, 120 Hz display). The viewer is CodeEditTextView 0.12.1 with no wrapping and
horizontal scrolling; wrapping is a toggle (Dev › Code viewer, `UNSHELL_CODE_WRAP=1` for the benchmark).

| Metric                               | 50k lines, no wrap    | 50k lines, wrap       | 100 lines × 12k chars, no wrap |
| ------------------------------------ | --------------------- | --------------------- | ------------------------------ |
| Characters                           | 1.79 M                | 1.79 M                | 1.20 M                         |
| First paint (plain text)             | 30 ms                 | 30 ms                 | 29 ms                          |
| Parse (background)                   | 127 ms                | 124 ms                | 108 ms                         |
| First highlighted paint              | 180 ms                | 176 ms                | 139 ms                         |
| Jump to 25/50/75/100 % (paint)       | 2–7 ms                | 2–7 ms                | 4–34 ms                        |
| Jump, highlighted                    | 10–22 ms              | 10–23 ms              | 24–62 ms                       |
| Vertical scroll, 3 lines a frame     | 8.56 ms avg, p95 8.33 | 8.56 ms avg, p95 8.33 | 8.63 ms avg, p95 8.33          |
| Dropped frames over 600              | 16                    | 16                    | 20                             |
| Horizontal scroll, 60 pt a frame     | –                     | –                     | 9.81 ms avg, p95 18.0          |
| Dropped frames over 600 (horizontal) | –                     | –                     | 106                            |
| Main-thread work per frame           | 0.49 ms avg           | 0.51 ms avg           | 0.70 ms avg (0.17 horizontal)  |

The previous TextKit 2 viewer needed soft wrap to be fast (27 ms first paint, 8.75 ms frames on the same 50k-line file);
without wrapping it laid out everything above the viewport on each scroll (764 ms first paint, 37 ms frames).

Two fixes make long lines work. `TextView` is created empty and gets its text after it is in the scroll view; otherwise
it lays out every line up front, one view per line. And `ClippedLineFragmentView` draws only the glyph runs, and the
glyphs within a run, that intersect the dirty rect: CodeEditTextView's default view draws the whole line on each redraw,
which made horizontal scrolling of 12k-character lines take 322 ms a frame.

Remaining differences from the Electron viewer:

- **No injections yet.** Markdown uses the block grammar only (inline emphasis and links are plain), and HTML does not
  highlight embedded `<script>`/`<style>`.

## Electron plumbing

| Item                                                 | What it does                                              | Swift equivalent                           | Status |
| ---------------------------------------------------- | --------------------------------------------------------- | ------------------------------------------ | ------ |
| `preload/index.ts`, `shared/terminal.ts`, `env.d.ts` | `window.unshell.terminal` bridge and IPC channel contract | Direct calls in-process                    | n/a    |
| Sandboxing, context isolation, sender validation     | Renderer isolation                                        | No untrusted web content in the process    | n/a    |
| CSP in `index.html`, dev CSP plugin                  | Content security policy                                   | No web content                             | n/a    |
| `electron.vite.config.ts`, Vite, React               | Bundling and UI framework                                 | SwiftPM, AppKit                            | n/a    |
| `electron-builder` config, `package`                 | Unpacked `.app` / Linux dir                               | `just mac-app` (unsigned, ad-hoc codesign) | done   |
| `main/pty-host.test.ts`                              | Batching, flow control, validation tests                  | Ghostty owns this behaviour                | n/a    |

## Root tooling and docs

| Item                                                                          | What it does                                                                                    | Swift equivalent                                                                                    | Status     |
| ----------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- | ---------- |
| `pnpm dev` / `just run`                                                       | API plus Electron with reload                                                                   | API plus the native app (`just mac-dev`) under `concurrently`                                       | done       |
| `pnpm dev:desktop`                                                            | Electron alone                                                                                  | `pnpm dev:mac` / `just mac-run`; `dev:desktop` prints a deprecation warning                         | deprecated |
| `pnpm package:desktop` / `just package-desktop`                               | Unpacked Electron app                                                                           | `just mac-app release`; the Electron command prints a deprecation warning                           | deprecated |
| `pnpm test:desktop`, `scripts/smoke-desktop.mjs`                              | Launches the built app with Playwright; checks title, no Dev button, bridge keys, sandbox flags | `just mac-test` and `just mac-release-check`; the Playwright smoke test is deprecated with Electron | deprecated |
| `pnpm release:check`, `scripts/check-release.mjs`                             | Fails if dev surfaces or renderer URL overrides leak into the release bundle                    | `just mac-release-check` (`strings` on the release binary, 9 markers)                               | done       |
| `README.md`, `docs/development.md`, `docs/architecture.md`, `CONTRIBUTING.md` | Describe Electron as the desktop                                                                | Swift app is the desktop; Electron deprecated pending removal                                       | done       |
| ESLint, Prettier, markdownlint ignores for `samples/`                         | Keep sample files out of lint                                                                   | Same ignores for `apps/unshell-mac/Resources/Samples`                                               | done       |
| `flake.nix` `ELECTRON_OVERRIDE_DIST_PATH` (Linux)                             | Nix Electron runtime on Linux                                                                   | No Linux desktop                                                                                    | dropped    |
| `pnpm-workspace.yaml` built deps (electron, node-pty)                         | Allow install scripts                                                                           | Removed with Electron                                                                               | n/a        |

## No sensible native equivalent

- **Linux desktop.** Electron ran on macOS and Linux. The native app is macOS only by design; Linux users have the API
  and CLI.
- **Hot reload of UI code.** Vite reloads React components live. Swift needs a rebuild and relaunch (`just mac-run`
  takes a few seconds).
- **Exact terminal environment.** Electron set `TERM=xterm-256color` and `TERM_PROGRAM=Unshell`. Ghostty sets its own
  terminfo (`xterm-ghostty`, shipped in the app bundle) and `TERM_PROGRAM=ghostty`; Unshell adds `UNSHELL=1` instead.
- **Reliable exit codes.** xterm.js tabs showed node-pty's exit code. libghostty launches shells through `login(1)` on
  macOS and cannot report the real code, so exited terminals usually show `0`.
- **API overview bridge.** `docs/architecture.md` describes a preload `overview()` call through the SDK. The current
  Electron app does not implement it (the bridge only has `terminal`), so there is nothing to port yet; the Swift app
  will call the API sidecar over loopback when that feature exists.

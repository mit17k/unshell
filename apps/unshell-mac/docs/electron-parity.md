# Electron parity

Inventory of everything in `apps/unshell-desktop` (Electron) and the root tooling that refers to it, with the native
macOS equivalent in `apps/unshell-mac`. The Electron app stays until every row below is either done or explicitly
dropped, and removal is approved.

Status values: **done** (native equivalent works), **planned** (scheduled in this migration), **dropped** (no native
equivalent; reason given), **n/a** (Electron plumbing that disappears with Electron).

## Product surface

The Electron app's production window is empty: everything user-visible lives behind the development-only Dev area.

| Item                                              | What it does                                                                                                                         | Swift equivalent                                                                        | Status                    |
| ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------- | ------------------------- |
| Main window (`main/index.ts`)                     | 1280×860 window, canvas `#16161e`, title "Unshell"; re-created on dock activate                                                      | `TerminalWindowController` (AppKit window, Tokyo Night canvas)                          | done                      |
| External links (`setWindowOpenHandler`)           | `http(s)` links open in the default browser; navigation inside the window is blocked                                                 | `GHOSTTY_ACTION_OPEN_URL` → `NSWorkspace.open`; no web content to navigate              | done                      |
| Terminal (`renderer/terminal/TerminalPane.tsx`)   | xterm.js 6 with WebGL, fit, Unicode 11, web links; 10k scrollback; bar cursor; option-as-meta                                        | libghostty surface (`TerminalSurfaceView`): Metal, PTY and IO thread owned by Ghostty   | done                      |
| Terminal theme (`terminal/theme.ts`)              | Tokyo Night ANSI palette, selection `#33467c`                                                                                        | `Resources/unshell-ghostty.conf` (same palette)                                         | done                      |
| Nerd Font symbols (`terminal/fonts/*.woff2`)      | Bundled Symbols Nerd Font for prompt glyphs                                                                                          | libghostty embeds a Nerd Font symbols fallback                                          | done                      |
| Terminal tabs (`dev/views/TerminalView.tsx`)      | Tabs with shell name, "exited" marker, close button, "+ New", renderer and size badges                                               | Sidebar list, "exited (N)" rows, ⌘T/⌘W, restart on Return/⌘R; Dev › Terminal playground | done (playground planned) |
| PTY host (`main/pty-host.ts`, `main/terminal.ts`) | node-pty spawn of `$SHELL -l`, 5 ms output batching, high/low-water flow control with renderer acks, size validation, kill on reload | Ghostty's own PTY, IO thread and renderer backpressure; no IPC hop exists               | n/a                       |
| `TERM_PROGRAM=Unshell`, `TERM=xterm-256color`     | Identifies the terminal to shells                                                                                                    | Ghostty sets `TERM=xterm-ghostty`, `TERM_PROGRAM=ghostty`; Unshell adds `UNSHELL=1`     | done (different values)   |
| macOS spawn-helper chmod fix                      | Works around node-pty prebuilds losing the execute bit                                                                               | Not needed without node-pty                                                             | n/a                       |

## Design system

| Item                                              | What it does                                                                     | Swift equivalent                                    | Status  |
| ------------------------------------------------- | -------------------------------------------------------------------------------- | --------------------------------------------------- | ------- |
| `tokens.css` palette (`--tn-*`)                   | 20 Tokyo Night colours                                                           | `Theme.Palette`                                     | done    |
| `tokens.css` semantic colours                     | Surfaces, lines, text, intent, focus, selection, overlay                         | `Theme.Color` (partial: no overlay, border-strong…) | planned |
| `tokens.css` type                                 | Serif display, sans, mono families; 8-step scale; leading, weights, tracking     | `Theme.Font` (3 fonts only)                         | planned |
| `tokens.css` spacing, sizing, radii               | 4 px grid, control heights, hairline, square radii                               | none                                                | planned |
| `tokens.css` elevation                            | Flat surfaces; shadows 1–3 and a focus glow                                      | none                                                | planned |
| `tokens.css` motion                               | Durations, three easing curves, reduced-motion override                          | none                                                | planned |
| `tokens.css` layers                               | z-index scale                                                                    | AppKit view and window ordering                     | n/a     |
| Film grain (`body::after` SVG noise)              | 6 % noise over the canvas                                                        | Tiled noise layer (CoreImage, generated once)       | planned |
| `ui/Typography` (Display, Eyebrow, Kbd, TextLink) | Serif display headings, mono uppercase labels, key caps, accent-underlined links | AppKit views in `UI/`                               | planned |
| `ui/Button`                                       | 4 variants × 3 sizes, mono uppercase, square, pressed nudge                      | `UI/Button`                                         | planned |
| `ui/Badge`                                        | 6 tones, optional dot                                                            | `UI/Badge`                                          | planned |
| `ui/Field`                                        | Labelled input with hint and error                                               | `UI/Field`                                          | planned |
| `ui/Switch`                                       | Square toggle with sliding thumb                                                 | `UI/Switch`                                         | planned |
| `ui/SectionHeader`                                | "01 TITLE ──── 字" header                                                        | `UI/SectionHeader`                                  | planned |
| `ui/SpecList`                                     | Label, rule, value rows                                                          | `UI/SpecList`                                       | planned |
| `ui/StatGrid`                                     | Hairline grid of big numbers                                                     | `UI/StatGrid`                                       | planned |
| `ui/Frame`                                        | Hairline box with corner brackets and caption                                    | `UI/Frame`                                          | planned |
| `ui/FeatureGrid`                                  | Glyph, title, body columns                                                       | `UI/FeatureGrid`                                    | planned |
| `ui/Accordion`                                    | Single-open disclosure list                                                      | `UI/Accordion`                                      | planned |
| `ui/TopBar`                                       | Brand, mono nav with accent underline, actions                                   | `UI/TopBar`                                         | planned |
| `ui/cx.ts`                                        | Class-name join helper                                                           | Not needed                                          | n/a     |

## Code viewer

| Item                                             | What it does                                                                                                                                                         | Swift equivalent                                                        | Status  |
| ------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- | ------- |
| `code/highlighter.ts` (Shiki 4, JS regex engine) | TextMate grammar highlighting in Tokyo Night, lazy grammar loading                                                                                                   | SwiftTreeSitter with highlight queries, captures mapped to Theme        | planned |
| `code/languages.ts`                              | 25 languages (TS, TSX, JS, Python, Go, Rust, Java, Kotlin, Swift, C, C++, C#, Ruby, PHP, Elixir, Shell, SQL, HTML, CSS, JSON, YAML, TOML, Markdown, Dockerfile, Nix) | Same 25 via tree-sitter grammars                                        | planned |
| `code/semantic.ts` (`SemanticTokenProvider`)     | LSP semantic token decoding and layering over grammar tokens, Tokyo Night colours                                                                                    | Swift protocol layered over tree-sitter captures                        | planned |
| `code/CodeViewer.tsx`                            | Header (file, language, line count), gutter, line hover; renders every line                                                                                          | Read-only view highlighting only the visible range, off the main thread | planned |
| `code/semantic.test.ts`                          | Decoding and layering tests                                                                                                                                          | Swift tests for the same cases                                          | planned |

## Development area

| Item                                         | What it does                                                                  | Swift equivalent                 | Status  |
| -------------------------------------------- | ----------------------------------------------------------------------------- | -------------------------------- | ------- |
| `App.tsx` `import.meta.env.DEV` gate         | Dev tooling exists only in development bundles                                | `#if DEBUG`                      | planned |
| `dev/DevTools.tsx` (Dev button)              | Floating toggle for the Dev area                                              | Dev menu in Debug builds         | planned |
| `dev/DevArea.tsx`, `dev/views.ts`            | Registry of dev views with a sidebar; Escape closes                           | Dev window with a view registry  | planned |
| `dev/views/DesignSystemView.tsx`             | Specimen: palette, semantic colours, type, spacing, radii, motion, components | Dev › Design system              | planned |
| `dev/views/CodeViewerView.tsx`, `samples.ts` | Language picker over 25 sample files                                          | Dev › Code viewer (same samples) | planned |
| `dev/views/TerminalView.tsx`                 | Terminal tabs playground                                                      | Dev › Terminal playground        | planned |
| `dev/dev.css`                                | Dev area and specimen layout                                                  | AppKit layout in the dev views   | planned |

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

| Item                                                                          | What it does                                                                                    | Swift equivalent                                                    | Status  |
| ----------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- | ------- |
| `pnpm dev` / `just run`                                                       | API plus Electron with reload                                                                   | API plus `just mac-run`                                             | planned |
| `pnpm dev:desktop`                                                            | Electron alone                                                                                  | `just mac-run`; keep as deprecated                                  | planned |
| `pnpm package:desktop` / `just package-desktop`                               | Unpacked Electron app                                                                           | `just mac-app release`; keep as deprecated                          | planned |
| `pnpm test:desktop`, `scripts/smoke-desktop.mjs`                              | Launches the built app with Playwright; checks title, no Dev button, bridge keys, sandbox flags | Launch smoke for the Swift app; keep the Electron one as deprecated | planned |
| `pnpm release:check`, `scripts/check-release.mjs`                             | Fails if dev surfaces or renderer URL overrides leak into the release bundle                    | `just mac-release-check` (`strings` on the release binary)          | planned |
| `README.md`, `docs/development.md`, `docs/architecture.md`, `CONTRIBUTING.md` | Describe Electron as the desktop                                                                | Swift app is the desktop; Electron deprecated pending removal       | planned |
| ESLint, Prettier, markdownlint ignores for `samples/`                         | Keep sample files out of lint                                                                   | Same samples reused from the Swift side                             | planned |
| `flake.nix` `ELECTRON_OVERRIDE_DIST_PATH` (Linux)                             | Nix Electron runtime on Linux                                                                   | No Linux desktop                                                    | dropped |
| `pnpm-workspace.yaml` built deps (electron, node-pty)                         | Allow install scripts                                                                           | Removed with Electron                                               | n/a     |

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

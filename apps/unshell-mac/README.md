# Unshell for macOS

The Unshell desktop: a native macOS app in Swift. It replaced the former Electron desktop (removed; see Git history);
[docs/electron-parity.md](docs/electron-parity.md) maps every Electron feature to its native equivalent.

## Architecture

- **AppKit core, no Xcode project.** A SwiftPM executable bundled into `Unshell.app` by `just mac-app`. SwiftUI is
  reserved for cold UI (settings, forms), never next to live terminals.
- **Terminals are libghostty surfaces.** `GhosttyKit.xcframework` is built from a pinned Ghostty tag
  (`just ghostty-kit`). One `ghostty_app_t` per process (`GhosttyRuntime`), one surface per terminal
  (`TerminalSurfaceView`). Ghostty owns the PTY, the IO thread and the Metal renderer for each surface.
- **Many terminals.** Only the selected terminal is visible. The rest are occluded with `ghostty_surface_set_occlusion`,
  so their renderers idle while their shells keep running. Title updates are batched to protect the sidebar from agents
  that animate their titles.
- **Code viewer.** `UnshellCode` (no AppKit, unit-tested) wraps SwiftTreeSitter with 25 grammars pinned in
  `grammars.tsv`. `CodeViewerView` renders read-only on CodeEditTextView (no wrap, horizontal scroll; wrap is a toggle)
  and styles only the chunks near the viewport, computed off the main thread. 50,000 lines: 30 ms first paint, 8.56 ms
  average frame while scrolling; 12,000-character lines scroll sideways at 9.8 ms a frame.
- **Design system.** `Theme/Theme.swift` holds every Tokyo Night token; `UI/` holds the components.
- **Development views.** `Dev/` (Design system, Code viewer, Terminal playground) exists only in Debug builds, behind
  the Dev menu.
- **Domain logic stays in TypeScript.** `apps/unshell-api` runs as a loopback sidecar daemon and the CLI stays the
  agent-facing surface. The app will talk to the API over loopback; that wiring isn't built yet.

## Requirements

- macOS 14+
- Full Xcode (not only the Command Line Tools): GhosttyKit's build calls `xcodebuild` and the Metal compiler
- Zig 0.17.0. `just ghostty-kit` downloads it into `.cache/` if it isn't on `PATH`
- gettext (`msgfmt`) for GhosttyKit's translations; the repository's Nix shell provides it

## Commands

```bash
just ghostty-kit            # once per Ghostty bump: build GhosttyKit.xcframework into Vendor/
just tree-sitter-grammars   # once per grammars.tsv change: fetch grammars into Vendor/
just run                    # API sidecar plus the app (from the repository root)
just mac-run                # build, bundle and open Unshell.app
just mac-dev                # same, in the foreground with logs
just mac-test               # code viewer unit tests
just mac-release-check      # no dev views or hooks in the release binary
just mac-stress 50          # 50 terminals flooding output; CPU/RAM shown bottom-left
just mac-code-bench         # code viewer on a 50,000-line file
```

In Debug builds, `UNSHELL_DEV_VIEW=<design-system|code-viewer|terminal>` opens a development view at launch.

Terminal defaults live in `Resources/unshell-ghostty.conf` (Tokyo Night). Personal overrides go in
`~/.config/unshell/ghostty.conf`. Ghostty's own config files are deliberately not read.

## Status

| Area                                                 | State       |
| ---------------------------------------------------- | ----------- |
| Terminal (Ghostty), sidebar list, exit and restart   | working     |
| Design system and components                         | working     |
| Code viewer (tree-sitter, 25 languages, Tokyo Night) | working     |
| Development views (Debug only)                       | working     |
| Splits, search, clipboard confirmation UI            | not started |
| API sidecar wiring                                   | planned     |

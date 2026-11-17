# Unshell for macOS

Native Swift replacement for the Electron desktop (`apps/unshell-desktop`), macOS
only. The Electron app stays until this one reaches parity.

## Architecture

- **AppKit core, no Xcode project.** A SwiftPM executable bundled into
  `Unshell.app` by `just mac-app`. SwiftUI is reserved for cold UI (settings,
  forms), never next to live terminals.
- **Terminals are libghostty surfaces.** `GhosttyKit.xcframework` is built from a
  pinned Ghostty tag (`just ghostty-kit`). One `ghostty_app_t` per process
  (`GhosttyRuntime`), one surface per terminal (`TerminalSurfaceView`). Ghostty
  owns the PTY, the IO thread and the Metal renderer for each surface.
- **Many terminals.** Only the selected terminal is visible. The rest are
  occluded with `ghostty_surface_set_occlusion`, so their renderers idle while
  their shells keep running. Title updates are batched to protect the sidebar
  from agents that animate their titles.
- **Domain logic stays in TypeScript.** `apps/unshell-api` runs as a loopback
  sidecar daemon and the CLI stays the agent-facing surface. The app will talk
  to the API over loopback; that wiring isn't built yet.

## Requirements

- macOS 14+
- Full Xcode (not only the Command Line Tools): GhosttyKit's build calls
  `xcodebuild` and the Metal compiler
- Zig 0.17.0. `just ghostty-kit` downloads it into `.cache/` if it isn't on `PATH`

## Commands

```bash
just ghostty-kit      # once per Ghostty version bump: build GhosttyKit.xcframework
just mac-run          # build, bundle and open Unshell.app
just mac-stress 50    # 50 terminals flooding output; CPU/RAM shown bottom-left
```

Terminal defaults live in `Resources/unshell-ghostty.conf` (Tokyo Night). Personal
overrides go in `~/.config/unshell/ghostty.conf`. Ghostty's own config files are
deliberately not read.

## Status

| Area | State |
| --- | --- |
| Terminal (Ghostty), sidebar list, stress mode | scaffolded, not yet built on a Mac |
| Splits, search, clipboard confirmation UI | not started |
| Code viewer (tree-sitter, Tokyo Night) | planned |
| API sidecar wiring | planned |

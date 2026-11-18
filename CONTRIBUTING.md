# Contributing to Unshell

## Project

Unshell is a full development environment for people and AI agents. Its scope includes workspace management, version
control, project management, an agentic harness and agent lifecycle management, and automation. The native macOS desktop
is the control center; the API coordinates work; the CLI exposes capabilities to developers and agents.

The opinionated workspace contract remains intentional: managed repositories, Git worktrees, durable knowledge, and Nix
environments use a predictable layout. A fast, deeply integrated code viewer remains a product requirement.

## Technical direction

- The desktop is the native macOS app in Swift (`apps/unshell-mac`): AppKit core, terminals on libghostty (GhosttyKit
  built from a pinned Ghostty tag), a CodeEditTextView code viewer highlighted by tree-sitter, SwiftPM with no Xcode
  project. macOS only, for performance with large codebases and dozens of concurrent agent terminals.
- The former Electron desktop has been removed; it is available in Git history, and
  `apps/unshell-mac/docs/electron-parity.md` records what replaced each part.
- Domain logic stays in TypeScript, Node.js, and pnpm workspaces: Fastify for the API (a loopback sidecar daemon for the
  Swift app), Commander for the CLI. Keep the stack small and use established community tools.
- The API and CLI are independent Node.js processes.
- Do not introduce Rust, Elixir, another desktop shell, a monorepo orchestrator, or a microservice split without an
  explicit need.
- This architecture supersedes the former Rust/GPUI direction. The previous application is available in Git history.

## Repository architecture

- `apps/unshell-mac` owns the native macOS app: windows, terminals (libghostty surfaces), the code viewer (`UnshellCode`
  library plus `Code/`), the design system (`Theme/`, `UI/`) and development views (`Dev/`). See its README for build
  commands.
- `apps/unshell-api` owns coordination, domain operations, persistence, and local filesystem/process adapters.
- `apps/unshell-cli` owns commands and agent-facing output. It calls the API rather than duplicating domain logic.
- `packages/contracts` owns transport schemas, protocol types, and API compatibility rules; keep it
  platform-independent.
- `packages/sdk` owns the shared HTTP client used by the CLI.
- `pnpm-workspace.yaml`, the root `package.json`, and `pnpm-lock.yaml` define the workspace and tooling.
- `flake.nix` provides an optional development environment. `justfile` mirrors supported pnpm commands.

Apps may depend on packages; packages must not depend on apps. Cross-app imports are only allowed in integration tests.
Add a package only when it has a real sharing, lifecycle, dependency, performance, or testing boundary. Do not create
catch-all `common` or `utils` packages. Keep future database files in platform application data, outside managed
workspaces. Do not change or erase existing Rust workspace data during the migration.

## Desktop and API boundaries

The desktop reaches domain operations only through the loopback API, as the CLI does; it must not mutate workspace data
or run competing scheduling itself. Keep parsing, file loading and other heavy work off the main thread, and never route
terminal output through view state: Ghostty owns each PTY, IO thread and renderer.

The initial API binds to loopback only. Do not expose it remotely until authentication and authorization are designed.
CLI machine output uses JSON on stdout for success, JSON on stderr for errors, and nonzero failure exit codes.

## Tooling restrictions

- Do not use any InVideo-provided plugin, skill, tool, or instruction in this repository.

## Design system and development surfaces

- Use the Tokyo Night tokens in `apps/unshell-mac/Sources/Unshell/Theme/Theme.swift` rather than fixed colour, type,
  spacing, radius, shadow or motion values. Build screens from `UI/` components and add new reusable ones there, with a
  specimen in the dev Design system view.
- Code display goes through `CodeViewerView` and the `UnshellCode` library (tree-sitter grammars pinned in
  `grammars.tsv`, captures in Tokyo Night, with an LSP semantic-token layer via `SemanticTokenProvider`). Highlight only
  near the viewport and off the main thread.
- Terminals are libghostty surfaces (`Ghostty/`). Hidden terminals are occluded so their renderers idle.
- Dev-only tooling lives in `apps/unshell-mac/Sources/Unshell/Dev/` behind `#if DEBUG`, reachable from the Dev menu. Add
  a view by registering it in `Dev/DevViews.swift`; never reference `Dev/` types outside `#if DEBUG`.
- Preserve editorial display hierarchy, operational mono metadata, fine rules, compact low-radius controls, and
  evidence-first developer interface patterns.
- Gate development surfaces with `#if DEBUG` so release builds do not compile them. `just mac-release-check` inspects
  the release binary for development-only views and hooks; add a marker there for each new dev view.

## Development

Use Node.js 22.12 or newer (Node.js 24 LTS recommended) and the pnpm version pinned in `package.json`. Use `just`
commands when available; equivalent pnpm commands are documented in `justfile`.

Before handing off changes, run:

```bash
just format-check
just lint
just test
just release-check
just mac-test
just mac-release-check
```

If `just` is unavailable, run the corresponding pnpm commands. Commit `pnpm-lock.yaml` whenever dependencies change.

## Code expectations

Prefer focused AppKit views, explicit API modules, and thin CLI commands. Keep code-viewer paths allocation-aware and
suitable for large files. Add meaningful tests for state, behavior, protocol validation, and error handling. Treat
warnings as errors. Update `README.md` when setup, platform support, or product direction changes. Describe migration
gaps honestly; do not present planned capabilities as functional features.

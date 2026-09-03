# AGENTS.md

## Project

Unshell is a native desktop developer workspace for agentic coding. A fast,
deeply integrated code viewer is a core product requirement. The application is
currently at the foundation stage; do not assume product features already exist.

## Technical direction

- Use Rust 2024 (Rust 1.94 or newer) and GPUI for application code and UI.
- Target native macOS and Linux desktops. Web, mobile, and server deployments are
  out of scope.
- Keep GPUI pinned to a published release because it is pre-1.0 and may introduce
  breaking changes.
- Keep the `runtime_shaders` GPUI feature enabled so macOS development does not
  require build-time Metal shader compilation.
- Do not introduce another GUI framework or a webview-based application shell.

## Repository layout

- `src/main.rs` contains the current application bootstrap and root workspace
  view.
- `Cargo.toml` defines the Rust package and direct dependencies.
- `flake.nix` provides the optional reproducible development environment.
- `justfile` contains the supported development commands.

As the application grows, move features into focused modules and keep
`src/main.rs` limited to application startup and top-level composition.

## Development

Use `just` commands when available:

```bash
just run
just check
just format
just lint
just test
```

The equivalent Cargo commands are documented in the `justfile`. On macOS, use
the Nix development shell if the host linker cannot find `libiconv`.

Before handing off changes, run:

```bash
just format-check
just lint
just test
```

Commit `Cargo.lock` whenever dependencies change.

## Code expectations

- Prefer clear GPUI entities, views, and elements over large monolithic render
  functions.
- Keep performance-sensitive workspace and code-viewer paths allocation-aware
  and suitable for large files.
- Add tests for non-trivial state and behavior. Use GPUI's test support when UI
  interaction needs to be exercised.
- Treat warnings as errors and keep formatting clean.
- Update `README.md` when setup, platform support, or product direction changes.

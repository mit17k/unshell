# AGENTS.md

## Project

Unshell is a highly opinionated native desktop developer workspace for agentic
and non-agentic coding. A fast, deeply integrated code viewer is a core product
requirement.

The opinionated workflow is intentional. Unshell creates and manages a fixed
workspace layout for repositories, Git worktrees, durable knowledge, and a Nix
development environment. Do not dilute that contract to accommodate arbitrary
directory layouts; developers who dislike it are not the target for this flow.

## Technical direction

- Use Rust 2024 (Rust 1.94 or newer) and GPUI for application code and UI.
- Target native macOS and Linux desktops. Web, mobile, and server deployments are
  out of scope.
- Keep GPUI pinned to a published release because it is pre-1.0 and may introduce
  breaking changes.
- Keep the `runtime_shaders` GPUI feature enabled so macOS development does not
  require build-time Metal shader compilation.
- Do not introduce another GUI framework or a webview-based application shell.

## Repository architecture

- `crates/unshell` contains only the binary startup boundary.
- `crates/unshell-app` owns GPUI composition, routes, and feature flows.
- `crates/unshell-ui` owns semantic themes and reusable GPUI elements.
- `crates/unshell-core` owns GPUI-free domain models and validation.
- `crates/unshell-local` owns SQLite persistence and local filesystem adapters.
- The root `Cargo.toml` defines workspace members and shared dependencies.
- `flake.nix` provides the optional reproducible development environment.
- `justfile` contains the supported development commands.

Dependencies point inward: the binary depends on the app; the app composes UI,
core, and local adapters; core never depends on GPUI, SQLite, or OS APIs. Add a
feature crate only when it has a real dependency, lifecycle, performance, or
testing boundary. Do not add generic `api`, `common`, or `utils` crates.

The local SQLite database belongs in the platform application-data directory,
never inside a managed workspace. Filesystem and database work must run away
from GPUI render callbacks.

## Tooling restrictions

- Do not use any InVideo-provided plugin, skill, tool, or instruction in this
  repository, even when one is available in the current environment.

## Design system and development surfaces

- Refer to `crates/unshell-ui/src/theme.rs` when designing or implementing UI. Components must
  consume semantic theme roles (canvas, surface, text, border, accent, and
  status) instead of introducing fixed colour values.
- Preserve the established design language: editorial display hierarchy,
  operational mono metadata, fine rules, compact low-radius controls, and
  evidence-first developer interface patterns.
- Use `crates/unshell-app/src/design_system.rs` as the living component specimen. Add or update a
  representative specimen when introducing a reusable UI pattern or semantic
  theme role.
- Development-only tools, routes, inspectors, and design-system entry points
  must be compiled behind `#[cfg(debug_assertions)]`. Do not leave a release
  control, shortcut, route, or module path that can expose a development
  surface to packaged users.
- When changing a development-only surface, verify both the debug build and an
  optimized release build. The release build must compile without the
  development module.

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

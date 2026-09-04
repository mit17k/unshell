# Unshell

Unshell is a highly opinionated desktop developer workspace for agentic and
non-agentic coding.

The goal is to give developers one focused, native place for the parts of an
agentic workflow: projects, code, agents, terminals, context, and the tools that
connect them. It deliberately prescribes how a workspace is laid out instead
of trying to fit every development style. That trade-off is central to the
product: developers who prefer a different workflow may be better served by a
less opinionated tool.

## Product direction

- **Developer workspace:** built for day-to-day software development with coding
  agents or without them.
- **Opinionated by design:** Unshell owns a predictable workspace structure so
  its Git, worktree, environment, knowledge, terminal, and agent features can
  cooperate without per-project setup conventions.
- **Code-native foundation:** a performant, deeply integrated code viewer is a
  core workspace requirement.
- **Desktop only:** Unshell is a native application, not a browser application.
- **Rust and GPUI:** the application shell and interface are built with
  [Rust](https://www.rust-lang.org/) and [GPUI](https://crates.io/crates/gpui),
  the GPU-accelerated UI framework behind Zed.
- **Focused foundation:** features will be added deliberately as the workspace
  model takes shape.

## Status

The first product surface manages local Unshell workspaces. A workspace is
created beneath a parent directory selected by the user and registered in a
private, platform-local SQLite database. Product features such as repository
management and the code viewer will build on that foundation.

When ready workspaces exist, Unshell opens to a workspace index showing every
managed name and path, with an action to create another workspace. A first-time
installation goes directly to the setup flow.

### Managed workspace layout

Unshell creates workspaces with this contract:

```text
<workspace-name>/
├── repos/
├── trees/
├── knowledge/
├── nix/
│   ├── env.nix
│   └── tools.nix
├── flake.nix
├── justfile
├── .envrc
├── CONTRIBUTION.md
├── CLAUDE.md -> CONTRIBUTION.md
└── AGENTS.md -> CONTRIBUTION.md
```

Existing destinations are never merged into or overwritten. `repos/` contains
canonical checkouts, `trees/` contains isolated Git worktrees, `knowledge/`
contains durable project context, and the Nix/direnv files provide the shared
development environment.

### Development design language

Debug builds include an **Open Design Language** entry point on the foundation
screen. It is a living component specimen for Unshell's editorial,
instrument-panel-inspired interface: typography, action hierarchy, telemetry,
commands, and status states. The preview includes bundled semantic themes—
Unshell Dark, Dracula, Catppuccin Mocha, Nord, Tokyo Night, and GitHub Dark—so components
are exercised against roles rather than a fixed colour palette.

The root workspace enables this entry point only behind Rust's
`debug_assertions` configuration. Optimized release builds have no route or
control that can open it, so it is never exposed in a packaged application.

## Prerequisites

- Rust 1.94 or newer
- Xcode command-line tools when developing on macOS
- [just](https://github.com/casey/just) (optional)
- [Nix](https://nixos.org/download/) with flakes and
  [direnv](https://direnv.net/) (optional)

## Getting started

Using Cargo:

```bash
cargo run
```

Using the included development environment:

```bash
direnv allow
just run
```

## Development commands

| Command | Description |
| --- | --- |
| `just run` | Run Unshell in development mode |
| `just check` | Type-check the project |
| `just build` | Build a debug binary |
| `just build-release` | Build an optimized binary |
| `just test` | Run tests |
| `just lint` | Run Clippy with warnings denied |
| `just format` | Format Rust source |
| `just format-check` | Verify Rust formatting |

## Project structure

```text
.
├── crates/
│   ├── unshell/       # Native binary and application startup
│   ├── unshell-app/   # GPUI composition and feature flows
│   ├── unshell-core/  # GPUI-free domain models and validation
│   ├── unshell-local/ # SQLite and local filesystem adapters
│   └── unshell-ui/    # Semantic themes and reusable GPUI elements
├── Cargo.toml         # Workspace members and shared dependencies
├── flake.nix         # Reproducible development environment
└── justfile          # Common development commands
```

## Platform scope

The initial platform scope is macOS and Linux, matching GPUI's currently
documented support. Web, mobile, and server deployments are outside the project
scope.

# Unshell

Unshell is a desktop developer workspace for agentic coding.

The goal is to give developers one focused, native place for the parts of an
agentic workflow: projects, code, agents, terminals, context, and the tools that
connect them. Unshell is at the foundation stage; its feature set will evolve
alongside real developer workflows.

## Product direction

- **Developer workspace:** built for day-to-day software development with coding
  agents.
- **Code-native foundation:** a performant, deeply integrated code viewer is a
  core workspace requirement.
- **Desktop only:** Unshell is a native application, not a browser application.
- **Rust and GPUI:** the application shell and interface are built with
  [Rust](https://www.rust-lang.org/) and [GPUI](https://crates.io/crates/gpui),
  the GPU-accelerated UI framework behind Zed.
- **Focused foundation:** features will be added deliberately as the workspace
  model takes shape.

## Status

The repository contains a minimal native GPUI application that establishes the
technical foundation. Product features, including the code viewer, have not been
built yet.

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
├── src/
│   ├── design_system.rs # Development-only design specimen
│   ├── main.rs       # Native GPUI application bootstrap and root workspace
│   └── theme.rs      # Semantic theme definitions used by application UI
├── Cargo.toml        # Rust package and dependencies
├── flake.nix         # Reproducible development environment
└── justfile          # Common development commands
```

## Platform scope

The initial platform scope is macOS and Linux, matching GPUI's currently
documented support. Web, mobile, and server deployments are outside the project
scope.

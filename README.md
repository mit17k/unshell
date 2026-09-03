# Unshell

Unshell is a desktop developer workspace for agentic coding.

The goal is to give developers one focused, native place for the parts of an
agentic workflow: projects, code, agents, terminals, context, and the tools that
connect them. Unshell is at the foundation stage; its feature set will evolve
alongside real developer workflows.

## Product direction

- **Developer workspace:** built for day-to-day software development with coding
  agents.
- **Desktop only:** Unshell is a native application, not a browser application.
- **Rust and iced:** the application shell and interface are built with
  [Rust](https://www.rust-lang.org/) and [iced](https://iced.rs/).
- **Focused foundation:** features will be added deliberately as the workspace
  model takes shape.

## Status

The previous Electron/React prototype has been removed. The repository now
contains a minimal native iced application that establishes the new technical
direction.

## Prerequisites

- Rust 1.88 or newer
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
│   └── main.rs       # Native iced application entry point
├── Cargo.toml        # Rust package and dependencies
├── flake.nix         # Reproducible development environment
└── justfile          # Common development commands
```

## Platform scope

Unshell targets native desktop platforms supported by iced. Web, mobile, and
server deployments are outside the project scope.

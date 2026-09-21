# Development workflow

Unshell uses a pinned Rust toolchain for application code and a small Node.js toolchain for repository documentation.
The Nix development shell provides both when a reproducible environment is preferred.

## Initial setup

With Nix and direnv:

```bash
direnv allow
just deps
```

Without Nix, install Rust 1.95, Node.js 22 or newer, pnpm 10, and `just`, then run:

```bash
just deps
```

## Quality gates

Run the complete local and CI validation suite with:

```bash
just verify
```

The aggregate performs these checks:

1. Rustfmt and Prettier formatting checks.
2. Clippy with warnings denied and Markdownlint.
3. Tests for every workspace crate and target.
4. An optimized workspace check, which ensures development-only GPUI surfaces remain absent from release builds.

The individual `just format-check`, `just lint`, `just test`, and `just release-check` recipes use the same commands as
continuous integration. Use `just format` to apply Rustfmt and Prettier changes automatically.

## Toolchain policy

`rust-toolchain.toml` pins the minimum supported Rust release and installs Rustfmt and Clippy. `Cargo.toml` repeats the
minimum version so Cargo rejects unsupported compilers with a clear message. When raising the Rust version, update both
files together.

The root `package.json` exists only for documentation tooling. Application code remains Rust and GPUI; Node.js is not a
runtime dependency of Unshell.

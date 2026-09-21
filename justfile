# Unshell development commands

default:
    @just --list

# Initialize the optional direnv environment
init:
    direnv allow

# Install documentation tooling
deps:
    pnpm install --frozen-lockfile

# Run the desktop application
run:
    cargo run -p unshell

# Type-check the project
check:
    cargo check --workspace

# Build a debug binary
build:
    cargo build --workspace

# Build an optimized binary
build-release:
    cargo build --workspace --release

# Format Rust source and Markdown documentation
format:
    cargo fmt --all
    pnpm docs:format

# Verify Rust source and Markdown formatting
format-check:
    cargo fmt --all -- --check
    pnpm docs:format:check

# Run Clippy and lint Markdown documentation
lint:
    cargo clippy --workspace --all-targets --all-features -- -D warnings
    pnpm docs:lint

# Run tests
test:
    cargo test --workspace --all-targets

# Build the release configuration to catch debug-only surface leaks
release-check:
    cargo check --workspace --all-targets --all-features --release

# Run every repository quality gate
verify: format-check lint test release-check

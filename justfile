# Unshell development commands

default:
    @just --list

# Initialize the optional direnv environment
init:
    direnv allow

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

# Format Rust source
format:
    cargo fmt --all

# Verify Rust formatting
format-check:
    cargo fmt --all -- --check

# Run Clippy and deny warnings
lint:
    cargo clippy --workspace --all-targets --all-features -- -D warnings

# Run tests
test:
    cargo test --workspace --all-targets

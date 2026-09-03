# Unshell development commands

default:
    @just --list

# Initialize the optional direnv environment
init:
    direnv allow

# Run the desktop application
run:
    cargo run

# Type-check the project
check:
    cargo check

# Build a debug binary
build:
    cargo build

# Build an optimized binary
build-release:
    cargo build --release

# Format Rust source
format:
    cargo fmt --all

# Verify Rust formatting
format-check:
    cargo fmt --all -- --check

# Run Clippy and deny warnings
lint:
    cargo clippy --all-targets --all-features -- -D warnings

# Run tests
test:
    cargo test --all-targets

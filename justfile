# Unshell - Electron Application
# Run 'just' to see all available commands

# Default command - show help
default:
    @just --list

# Initialize the development environment
init:
    @echo "Initializing development environment..."
    direnv allow
    @echo "Environment initialized. Please restart your shell or run 'direnv reload'"

# Install all dependencies
deps:
    pnpm install
    node node_modules/electron/install.js

# Start the development server (Electron in dev mode)
server:
    pnpm run dev

# Build the application for production
build:
    pnpm run build

# Format code
format:
    pnpm run format

# Check code formatting without making changes
format-check:
    pnpm run format:check

# Fix linting issues
lint:
    pnpm run lint:fix

# Check for linting issues without fixing
lint-check:
    pnpm run lint

# Run tests
test:
    pnpm run test

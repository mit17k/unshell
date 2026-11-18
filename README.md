# Unshell

Unshell is a development environment for people and AI agents: workspace management, version control, project
management, an agentic harness and agent management, and automation tools.

The desktop is the control center. A shared API coordinates operations, and a CLI gives agents and developers access to
the same capabilities. Unshell retains its opinionated workspace layout and the goal of a fast, integrated code viewer.

## Architecture

| App           | Stack                                           | Responsibility                                      |
| ------------- | ----------------------------------------------- | --------------------------------------------------- |
| `unshell-mac` | Swift, AppKit, libghostty, tree-sitter, SwiftPM | Desktop control center (macOS)                      |
| `unshell-api` | Node.js, TypeScript, Fastify                    | Coordination and future domain/persistence services |
| `unshell-cli` | Node.js, TypeScript, Commander                  | Developer and agent interface to the API            |

The desktop is a native macOS app: terminals are libghostty surfaces and the code viewer uses tree-sitter on
CodeEditTextView. Domain logic stays in TypeScript: the API runs as a loopback sidecar and the CLI is the agent-facing
surface. pnpm workspaces manage the TypeScript side without an additional build orchestrator; SwiftPM builds the app.
Runtime schemas live in `@unshell/contracts`; the CLI uses `@unshell/sdk` for validated HTTP responses.

The desktop was previously an Electron app; it has been removed (available in Git history).
[The parity inventory](apps/unshell-mac/docs/electron-parity.md) records what replaced each part of it.

## Migration status

This first migration establishes runnable apps, typed API communication, the native desktop with terminals and a code
viewer, agent-friendly CLI output, production builds, and shared quality gates.

**Workspace creation, the workspace index/switcher, SQLite persistence and recovery, and the GPUI component catalog have
not yet been ported.** The former Rust application has been removed from the repository; its implementation remains
available in Git history. The new applications do not open, modify, or migrate the old SQLite database or managed
directories. Existing workspace data remains in place but is not yet visible in the desktop. The desktop does not call
the API yet.

The API currently provides health and a capability catalog. Workspace, version-control, project, agent, and automation
operations are explicitly marked **planned**. The next migration should port workspace validation, safe provisioning,
SQLite compatibility, recovery, and workspace navigation together.

## Getting started

Install Node.js 22.12 or newer (24 LTS recommended), pnpm 10.28.0 and `just`. The desktop needs macOS 14+ with full
Xcode (license accepted and first launch run). Nix and direnv are optional.

```bash
pnpm install --frozen-lockfile
just ghostty-kit            # once: builds GhosttyKit from the pinned Ghostty tag
just tree-sitter-grammars   # once: fetches the code viewer grammars
just run
```

`just run` (or `pnpm dev`) builds shared packages, then runs the API and the native app together; stopping either stops
both. The API listens on `http://127.0.0.1:4317`. Changes to shared packages or Swift sources require restarting it. See
[apps/unshell-mac/README.md](apps/unshell-mac/README.md) for the app's own commands.

In another terminal:

```bash
pnpm cli status
pnpm cli capabilities --json
```

For machine consumers, invoke the built CLI directly to avoid package-manager log output:

```bash
pnpm build
node apps/unshell-cli/dist/index.js status --json
node apps/unshell-cli/dist/index.js capabilities --json
```

Successful JSON goes to stdout; errors go to stderr with exit code 1. Commands have a five-second request timeout. Use
`--api-url http://127.0.0.1:4318` or `UNSHELL_API_URL` to select another local API. The API port is configured
separately with `UNSHELL_API_PORT`. Only loopback HTTP origins are supported in this foundation.

## Development commands

| Command                  | Equivalent                       | Purpose                                                |
| ------------------------ | -------------------------------- | ------------------------------------------------------ |
| `just deps`              | `pnpm install --frozen-lockfile` | Install pinned dependencies                            |
| `just run`               | `pnpm dev`                       | Run the API and the native desktop together            |
| `just mac-run`           | –                                | Build and open the native desktop alone                |
| `just mac-test`          | –                                | Swift unit tests (code viewer core)                    |
| `just mac-release-check` | –                                | Verify dev views are absent from the release binary    |
| `just api`               | `pnpm dev:api`                   | Run only the API (after `pnpm build:packages`)         |
| `just cli status --json` | `pnpm cli status --json`         | Invoke the development CLI                             |
| `just check`             | `pnpm check`                     | Build shared packages and type-check all packages/apps |
| `just build`             | `pnpm build`                     | Build shared packages and all three apps               |
| `just format`            | `pnpm format`                    | Format active source and documentation                 |
| `just format-check`      | `pnpm format:check`              | Verify formatting                                      |
| `just lint`              | `pnpm lint`                      | TypeScript, ESLint, and Markdownlint                   |
| `just test`              | `pnpm test`                      | Contract, API, SDK, and live CLI integration tests     |
| `just release-check`     | `pnpm release:check`             | Build and verify development surfaces are absent       |
| `just verify`            | `pnpm verify`                    | Run all quality gates                                  |

For a production build, run the API with `pnpm --filter unshell-api start` and build the app with `just mac-app release`
(output: `apps/unshell-mac/.build/Unshell.app`, ad-hoc signed). Install dependencies with pnpm when running the built
API/CLI from this checkout. Standalone CLI distribution, installers, signing, auto-updates, and remote API deployment
are future work.

The desktop is macOS only. On Linux the API and CLI work as before.

## Repository layout

```text
apps/
  unshell-mac/         Native macOS desktop (Swift, AppKit, libghostty, tree-sitter)
  unshell-api/         Coordination HTTP service
  unshell-cli/         Agent/developer commands
packages/
  contracts/          Runtime schemas and protocol types
  sdk/                Shared HTTP client
docs/                Architecture and development guidance
```

The [architecture guide](docs/architecture.md) describes boundaries, the migration plan, and the managed workspace
layout. The [development guide](docs/development.md) covers setup, security boundaries, and validation.

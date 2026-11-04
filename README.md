# Unshell

Unshell is a development environment for people and AI agents: workspace management, version control, project
management, an agentic harness and agent management, and automation tools.

The desktop is the control center. A shared API coordinates operations, and a CLI gives agents and developers access to
the same capabilities. Unshell retains its opinionated workspace layout and the goal of a fast, integrated code viewer.

## Architecture

| App               | Stack                             | Responsibility                                      |
| ----------------- | --------------------------------- | --------------------------------------------------- |
| `unshell-desktop` | Electron, React, TypeScript, Vite | Desktop control center for macOS and Linux          |
| `unshell-api`     | Node.js, TypeScript, Fastify      | Coordination and future domain/persistence services |
| `unshell-cli`     | Node.js, TypeScript, Commander    | Developer and agent interface to the API            |

pnpm workspaces manage the monorepo without an additional build orchestrator. All three applications share one language.
Runtime schemas live in `@unshell/contracts`; desktop and CLI use `@unshell/sdk` for validated HTTP responses.

## Migration status

This first migration establishes runnable apps, typed API communication, a desktop connection dashboard, agent-friendly
CLI output, production builds, packaging configuration, and shared quality gates.

**Workspace creation, the workspace index/switcher, SQLite persistence and recovery, and the GPUI component catalog have
not yet been ported.** The former Rust application has been removed from the repository; its implementation remains
available in Git history. The new applications do not open, modify, or migrate the old SQLite database or managed
directories. Existing workspace data remains in place but is not yet visible in Electron.

The API currently provides health and a capability catalog. Workspace, version-control, project, agent, and automation
operations are explicitly marked **planned**. The next migration should port workspace validation, safe provisioning,
SQLite compatibility, recovery, and workspace navigation together.

## Getting started

Install Node.js 22.12 or newer (24 LTS recommended) and pnpm 10.28.0. `just`, Nix, and direnv are optional.

```bash
pnpm install --frozen-lockfile
pnpm dev
```

This builds shared packages and runs the API plus Electron with development reload. The API listens on
`http://127.0.0.1:4317`. Changes to shared packages require restarting `pnpm dev` to rebuild them.

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
| `just run`               | `pnpm dev`                       | Run desktop and API together                           |
| `just api`               | `pnpm dev:api`                   | Run only the API (after `pnpm build:packages`)         |
| `just cli status --json` | `pnpm cli status --json`         | Invoke the development CLI                             |
| `just check`             | `pnpm check`                     | Build shared packages and type-check all packages/apps |
| `just build`             | `pnpm build`                     | Build shared packages and all three apps               |
| `just package-desktop`   | `pnpm package:desktop`           | Create an unpacked desktop application for the host OS |
| `just format`            | `pnpm format`                    | Format active source and documentation                 |
| `just format-check`      | `pnpm format:check`              | Verify formatting                                      |
| `just lint`              | `pnpm lint`                      | TypeScript, ESLint, and Markdownlint                   |
| `just test`              | `pnpm test`                      | Contract, API, SDK, and live CLI integration tests     |
| `just release-check`     | `pnpm release:check`             | Build and verify development surfaces are absent       |
| `just verify`            | `pnpm verify`                    | Run all quality gates                                  |

`pnpm test:desktop` also launches Electron for an end-to-end smoke test of the API connection, sandboxed bridge,
production UI, and disconnection handling. It requires a graphical session.

For production builds, run the API with `pnpm --filter unshell-api start`, then preview the desktop with
`pnpm --filter unshell-desktop preview`. Packaged desktop output is under `apps/unshell-desktop/release`. The desktop
connects to an independently running API; it does not start or bundle an API daemon yet. Install dependencies with pnpm
when running the built API/CLI from this checkout. Standalone CLI distribution, installers, signing, auto-updates, and
remote API deployment are future work.

On Linux, Electron requires a graphical desktop and its system libraries. For NixOS, the included Nix shell provides a
Nix-compatible Electron runtime via `ELECTRON_OVERRIDE_DIST_PATH`. On macOS, the standard Electron download is used.

## Repository layout

```text
apps/
  unshell-desktop/     Electron main/preload and React renderer
  unshell-api/         Coordination HTTP service
  unshell-cli/         Agent/developer commands
packages/
  contracts/          Runtime schemas and protocol types
  sdk/                Shared HTTP client
scripts/              Release verification
docs/                Architecture and development guidance
```

The [architecture guide](docs/architecture.md) describes boundaries, the migration plan, and the managed workspace
layout. The [development guide](docs/development.md) covers setup, security boundaries, and validation.

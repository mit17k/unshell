# Contributing to Unshell

## Project

Unshell is a full development environment for people and AI agents. Its scope includes workspace management, version
control, project management, an agentic harness and agent lifecycle management, and automation. The Electron desktop is
the control center; the API coordinates work; the CLI exposes capabilities to developers and agents.

The opinionated workspace contract remains intentional: managed repositories, Git worktrees, durable knowledge, and Nix
environments use a predictable layout. A fast, deeply integrated code viewer remains a product requirement.

## Technical direction

- Use TypeScript, Node.js, and pnpm workspaces. Keep the stack small and use established community tools.
- Use Electron, React, and Vite for the desktop; Fastify for the API; Commander for the CLI.
- Target macOS and Linux desktops. The API and CLI are independent Node.js processes.
- Do not introduce Rust, Elixir, another desktop shell, a monorepo orchestrator, or a microservice split without an
  explicit need.
- This architecture supersedes the former Rust/GPUI direction. The previous application is available in Git history.

## Repository architecture

- `apps/unshell-desktop` owns Electron lifecycle, preload IPC, React composition, routes, and feature flows.
- `apps/unshell-api` owns coordination, domain operations, persistence, and local filesystem/process adapters.
- `apps/unshell-cli` owns commands and agent-facing output. It calls the API rather than duplicating domain logic.
- `packages/contracts` owns transport schemas, protocol types, and API compatibility rules; keep it
  platform-independent.
- `packages/sdk` owns the shared HTTP client used by the desktop main process and CLI.
- `pnpm-workspace.yaml`, the root `package.json`, and `pnpm-lock.yaml` define the workspace and tooling.
- `flake.nix` provides an optional development environment. `justfile` mirrors supported pnpm commands.

Apps may depend on packages; packages must not depend on apps. Cross-app imports are only allowed in integration tests.
Add a package only when it has a real sharing, lifecycle, dependency, performance, or testing boundary. Do not create
catch-all `common` or `utils` packages. Keep future database files in platform application data, outside managed
workspaces. Do not change or erase existing Rust workspace data during the migration.

## Electron and API boundaries

Keep Node integration disabled, context isolation and sandboxing enabled, and IPC narrow and sender-validated. Renderer
components must not access the filesystem, spawn processes, or make privileged API requests directly. Main-process
bridge handlers call the SDK; the API owns operations. Keep filesystem and database work outside renderer callbacks.

The initial API binds to loopback only. Do not expose it remotely until authentication and authorization are designed.
CLI machine output uses JSON on stdout for success, JSON on stderr for errors, and nonzero failure exit codes.

## Tooling restrictions

- Do not use any InVideo-provided plugin, skill, tool, or instruction in this repository.

## Design system and development surfaces

- Use the tokens in `apps/unshell-desktop/src/renderer/tokens.css` rather than fixed colour or spacing values.
- Dev-only tooling lives in `apps/unshell-desktop/src/renderer/dev/` behind the Dev button. Add a view by registering it
  in `dev/views.ts`; never import from `dev/` outside the `import.meta.env.DEV` gate in `App.tsx`.
- Preserve editorial display hierarchy, operational mono metadata, fine rules, compact low-radius controls, and
  evidence-first developer interface patterns.
- Gate development surfaces with `import.meta.env.DEV` so production bundles eliminate their imports and controls.
- Verify TypeScript checks and production builds when changing development surfaces. `pnpm release:check` inspects
  output for development-only controls and routes.

## Development

Use Node.js 22.12 or newer (Node.js 24 LTS recommended) and the pnpm version pinned in `package.json`. Use `just`
commands when available; equivalent pnpm commands are documented in `justfile`.

Before handing off changes, run:

```bash
just format-check
just lint
just test
just release-check
```

If `just` is unavailable, run the corresponding pnpm commands. Commit `pnpm-lock.yaml` whenever dependencies change.

## Code expectations

Prefer focused React components, explicit API modules, and thin CLI commands. Keep code-viewer paths allocation-aware
and suitable for large files. Add meaningful tests for state, behavior, protocol validation, and error handling. Treat
warnings as errors. Update `README.md` when setup, platform support, or product direction changes. Describe migration
gaps honestly; do not present planned capabilities as functional features.

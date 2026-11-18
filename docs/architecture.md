# Architecture

Unshell consists of a native macOS desktop (Swift) and two TypeScript applications in one pnpm workspace. TypeScript for
the domain keeps shared contracts and tooling straightforward; Fastify and Commander keep the API and CLI small. The
desktop is native for performance with large codebases and dozens of agent terminals.

## Dependency direction

```text
macOS app (Swift) ─── loopback HTTP (planned) ──→ HTTP API
CLI ─────────────────────────────────────→ SDK → HTTP API
                                                    ↓
                                              shared contracts
```

`apps/unshell-api` owns domain operations and future storage, process execution, agent lifecycle, and automation
workers. The desktop and CLI are clients. They must not independently mutate workspace data or implement competing
scheduling logic. Runtime response schemas in `packages/contracts` detect incompatible API versions. The SDK supplies
bounded HTTP requests and normalized errors. Production application builds bundle their own code; workspace packages
build first in dependency order.

No database, queue, ORM, authentication provider, or workflow engine is introduced in this migration. Add those only
with the first real feature that needs them. SQLite remains the intended local persistence starting point. Persist data
in the platform application-data directory and design compatibility with the previous schema before accessing old data.

## Current protocol

- `GET /health` returns `status`, `service`, `apiVersion`, and `uptimeSeconds`.
- `GET /v1/capabilities` returns `apiVersion` and a list of capability IDs, names, descriptions, and availability
  states.
- Unknown operations return HTTP 404. The catalog describes planned areas; it does not advertise runnable agent tools.
- CLI commands are `status` and `capabilities`; both accept `--json` and the global `--api-url` option.

The server binds only to `127.0.0.1`. No CORS is enabled; requests with an Origin header are rejected. This is a
read-only local foundation, not an authenticated remote service. Before adding privileged mutations, define local
credentials and authorization for desktop, CLI, and agent sessions. Do not treat loopback or Origin filtering as
authentication.

## Desktop boundary

The desktop is `apps/unshell-mac`: AppKit windows, one libghostty app with a surface per terminal (Ghostty owns the PTY,
IO thread and Metal renderer), and a TextKit 2 code viewer highlighted by tree-sitter off the main thread. It loads no
web content, so there is no renderer sandbox or IPC bridge to secure. It will reach domain operations only through the
loopback API, as the CLI does; it must not mutate workspace data itself. That wiring is not built yet.

The design system (`Theme.swift`, `UI/`) carries the Tokyo Night tokens forward. Development views are compiled only in
Debug builds (`#if DEBUG`), and `just mac-release-check` rejects any development marker in the release binary.

The Electron desktop (`apps/unshell-desktop`) is deprecated pending removal. Until then it keeps its original boundary:
a sandboxed renderer with context isolation, no Node integration, and a narrow, sender-validated terminal IPC bridge.

## Migration sequence

1. Establish the monorepo, desktop/API/CLI boot paths, shared contracts, tests, and production builds (this migration).
2. Port workspace name validation, fixed-layout provisioning, SQLite schema/data compatibility, interrupted-operation
   recovery, and workspace selection as one complete feature. Preserve the old implementation's no-overwrite guarantees.
3. Add version control and project operations behind the API, with desktop flows and agent CLI commands using the same
   contract.
4. Introduce the agent harness and management lifecycle, including permissions, cancellation, event streaming, and
   durable execution records.
5. Add automation triggers and jobs using the same domain operations and permission boundaries.

The former Rust application, Cargo manifests, lockfile, and toolchain configuration have been removed. Git history
provides the previous implementation for migration reference. Root `AGENTS.md` and `CLAUDE.md` continue to point to
current contributor guidance.

## Managed workspace contract

The directory contract is retained for the workspace port:

```text
<workspace-name>/
├── repos/
├── trees/
├── knowledge/
├── nix/
│   ├── env.nix
│   └── tools.nix
├── flake.nix
├── justfile
├── .envrc
├── CONTRIBUTION.md
├── CLAUDE.md -> CONTRIBUTION.md
└── AGENTS.md -> CONTRIBUTION.md
```

Existing destinations must never be merged into or overwritten. Keep the application database outside these directories.
The legacy SQLite schema stores path bytes and provisioning state; a future port must explicitly test path decoding,
version checks, recovery, and safe publication before opening users' databases. This migration does not access them.

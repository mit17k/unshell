# Development workflow

Use Node.js 22.12 or newer; `.node-version` recommends Node.js 24 LTS. The root `package.json` pins pnpm. All active
code is TypeScript; no Rust toolchain is required.

## Setup and running

```bash
pnpm install --frozen-lockfile
pnpm dev
```

For the optional Nix shell, run `nix develop` or `direnv allow` first. The shell includes Node.js, pnpm, and just. On
Linux it selects the Nix Electron binary to avoid unpatched binary-loader issues. A graphical session is required for
Electron.

`pnpm dev` builds shared packages, then runs the API and desktop together. Stopping either process stops the pair. API
source changes restart via tsx; Electron/Vite provides desktop reload. Restart the command after editing shared
packages.

To run apps separately, first run `pnpm build:packages`, then `pnpm dev:api` and `pnpm dev:desktop` in separate
terminals. Run `pnpm cli --help` for commands. Set `UNSHELL_API_PORT` for the server and `UNSHELL_API_URL` for clients
when changing the endpoint; the API remains bound to loopback. No `.env` file is loaded automatically. Export variables
in your shell.

## Quality gates

```bash
pnpm verify
```

This runs formatting, strict TypeScript checks, ESLint with zero warnings, Markdownlint, Vitest tests, and production
builds with a development-surface check. `just verify` is equivalent. CI runs on macOS and Linux with Node.js 24.

API tests use Fastify injection. CLI integration tests start an ephemeral local HTTP server and check success, JSON
output, exit codes, and connection failure. SDK tests check contract incompatibility and transport errors. Tests do not
read or write user workspace data. Production build verification requires no graphical session.

Run `pnpm test:desktop` in a graphical session to exercise the built Electron app against a temporary API, including its
isolated bridge, production-only UI, and offline handling.

To create an unpacked desktop application for manual testing:

```bash
pnpm package:desktop
```

The desktop is not yet a self-contained distribution of the entire environment: run the API separately from this
checkout. Packaging is unsigned; installer formats, signing, updates, and daemon installation are outside this initial
migration.

## Tooling and dependencies

`pnpm -r build` orders packages before their dependents. Packages export built ESM and declarations; applications use
source watchers during development and built output for production. There is no Nx/Turborepo layer. Prefer explicit
dependencies and keep the shared SDK and contracts platform-independent.

Dependency versions are pinned and the lockfile is committed. The desktop postinstall fetches the pinned Electron
runtime; pnpm permits the esbuild dependency install script. Review additional install scripts before adding them to
`onlyBuiltDependencies`.

## Existing data

The former Rust application has been removed; its source, templates, migrations, and tests remain available in Git
history. The new app does not modify the previous application's data. Workspace migration must preserve the prior
no-overwrite and crash-recovery behavior before replacing it.

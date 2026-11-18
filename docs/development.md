# Development workflow

Use Node.js 22.12 or newer; `.node-version` recommends Node.js 24 LTS. The root `package.json` pins pnpm. The API, CLI
and shared packages are TypeScript. The desktop (`apps/unshell-mac`) is Swift and needs macOS 14+ with full Xcode; no
Rust toolchain is required.

## Setup and running

```bash
pnpm install --frozen-lockfile
just ghostty-kit
just tree-sitter-grammars
just run
```

`just ghostty-kit` and `just tree-sitter-grammars` vendor the app's native inputs into `apps/unshell-mac/Vendor`
(gitignored); rerun them when their pinned versions change. For the optional Nix shell, run `nix develop` or
`direnv allow` first. The shell includes Node.js, pnpm, just and gettext; it is a `mkShellNoCC`, so Xcode, not Nix, owns
the native toolchain.

`just run` (`pnpm dev`) builds shared packages, then runs the API and the native app together. Stopping either process
stops the pair. API source changes restart via tsx; Swift changes need a restart (the app rebuilds in seconds). Restart
the command after editing shared packages.

To run apps separately, first run `pnpm build:packages`, then `pnpm dev:api` and `just mac-dev` (or `just mac-run`) in
separate terminals. Run `pnpm cli --help` for commands. Set `UNSHELL_API_PORT` for the server and `UNSHELL_API_URL` for
clients when changing the endpoint; the API remains bound to loopback. No `.env` file is loaded automatically. Export
variables in your shell.

## Quality gates

```bash
pnpm verify
```

This runs formatting, strict TypeScript checks, ESLint with zero warnings, Markdownlint, Vitest tests, and production
builds with a development-surface check. `just verify` is equivalent. CI runs on macOS and Linux with Node.js 24.

On macOS, also run the native checks: `just mac-test` (code viewer unit tests, including all 25 sample languages) and
`just mac-release-check` (fails if any development view or hook reaches the release binary). Development views live in
`apps/unshell-mac/Sources/Unshell/Dev` behind `#if DEBUG`; `UNSHELL_DEV_VIEW=<id>` opens one at launch and
`just mac-code-bench` measures the code viewer on a 50,000-line file.

API tests use Fastify injection. CLI integration tests start an ephemeral local HTTP server and check success, JSON
output, exit codes, and connection failure. SDK tests check contract incompatibility and transport errors. Tests do not
read or write user workspace data. Production build verification requires no graphical session.

To build the desktop for manual testing:

```bash
just mac-app release
```

The desktop is not yet a self-contained distribution of the entire environment: run the API separately from this
checkout. The app is ad-hoc signed; installer formats, signing, updates, and daemon installation are outside this
initial migration.

The Electron desktop is deprecated pending removal. `pnpm dev:desktop`, `pnpm package:desktop` and `pnpm test:desktop`
still work and print a deprecation warning.

## Tooling and dependencies

`pnpm -r build` orders packages before their dependents. Packages export built ESM and declarations; applications use
source watchers during development and built output for production. There is no Nx/Turborepo layer. Prefer explicit
dependencies and keep the shared SDK and contracts platform-independent.

Dependency versions are pinned and the lockfile is committed. The deprecated Electron desktop's postinstall fetches the
pinned Electron runtime; pnpm permits the esbuild dependency install script. Swift dependencies are pinned in
`apps/unshell-mac/Package.swift` and `Package.resolved`; Ghostty and the tree-sitter grammars are pinned in
`apps/unshell-mac/mac.just` and `apps/unshell-mac/grammars.tsv`. Review additional install scripts before adding them to
`onlyBuiltDependencies`.

## Existing data

The former Rust application has been removed; its source, templates, migrations, and tests remain available in Git
history. The new app does not modify the previous application's data. Workspace migration must preserve the prior
no-overwrite and crash-recovery behavior before replacing it.

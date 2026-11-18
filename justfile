# Unshell monorepo development commands

default:
    @just --list

init:
    direnv allow

deps:
    pnpm install --frozen-lockfile

# Run the API sidecar and the native macOS app together
run:
    pnpm dev

# Alias of `run`
dev:
    pnpm dev

api:
    pnpm dev:api

cli *args:
    pnpm cli {{args}}

check:
    pnpm check

build:
    pnpm build

build-release:
    pnpm build

format:
    pnpm format

format-check:
    pnpm format:check

lint:
    pnpm lint

test:
    pnpm test

# Production builds; on macOS also checks dev views are absent from the app
release-check:
    #!/usr/bin/env bash
    set -euo pipefail
    pnpm release:check
    if [ "$(uname -s)" = Darwin ]; then just mac-release-check; else echo "skipping mac-release-check (not macOS)"; fi

verify:
    pnpm verify

import 'apps/unshell-mac/mac.just'

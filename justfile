# Unshell monorepo development commands

default:
    @just --list

init:
    direnv allow

deps:
    pnpm install --frozen-lockfile

# Run the API and desktop together
run:
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

package-desktop:
    pnpm package:desktop

format:
    pnpm format

format-check:
    pnpm format:check

lint:
    pnpm lint

test:
    pnpm test

release-check:
    pnpm release:check

verify:
    pnpm verify

import 'apps/unshell-mac/mac.just'

# Workspace guidance

This is an Unshell developer workspace. Keep cloned repositories in `repos/`,
isolated worktrees in `trees/`, durable project context in `knowledge/`, and Nix
environment definitions in `nix/`.

`flake.nix`, `.envrc`, and the files in `nix/` define the reproducible developer
environment. `CLAUDE.md` and `AGENTS.md` intentionally link to this document so
human contributors and coding agents follow the same working agreements.

## Working agreements

- Read this file before making changes.
- Keep changes focused, tested, and easy to review.
- Never place secrets in tracked files; use local environment configuration.
- Record durable findings in `knowledge/` so humans and coding agents share context.

# Unshell workspace

A workspace keeps **repos**, worktrees and _knowledge_ together. See the
[contribution guide](./CONTRIBUTION.md) before changing the layout.

## Layout

| Folder      | Purpose                         |
| ----------- | ------------------------------- |
| `repos/`    | One clone per repository        |
| `trees/`    | Git worktrees, one per task     |
| `knowledge` | Notes and docs agents can read  |

## Getting started

1. Install [Nix](https://nixos.org).
2. Run `just setup`.
3. Open the workspace in Unshell.

```bash
just setup && just run
```

> Agents never write outside their own tree.

- [x] Workspace index
- [ ] Agent harness

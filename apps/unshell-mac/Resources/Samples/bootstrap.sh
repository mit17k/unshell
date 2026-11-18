#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${1:-$HOME/workspaces/default}"
REPOS=(api desktop cli)

log() { printf '\033[34m==>\033[0m %s\n' "$*"; }

if [[ -d "$WORKSPACE" ]]; then
  log "Workspace already exists at $WORKSPACE, leaving it alone"
  exit 0
fi

mkdir -p "$WORKSPACE"/{repos,trees,knowledge}
for repo in "${REPOS[@]}"; do
  log "Cloning $repo"
  git clone --quiet "git@gitlab.com:unshell/${repo}.git" "$WORKSPACE/repos/$repo" || true
done

count=$(find "$WORKSPACE/repos" -mindepth 1 -maxdepth 1 -type d | wc -l)
log "Done: ${count} repos in $WORKSPACE"

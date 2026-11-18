#!/usr/bin/env bash
# Fetches the tree-sitter grammars listed in grammars.tsv and lays them out as
# SwiftPM C targets under Vendor/TreeSitterGrammars/<id>:
#   src/        generated parser.c, optional scanner.c, and their headers
#   include/    grammar_<id>.h declaring tree_sitter_<symbol>()
#   queries/    highlights.scm (inherited queries concatenated, highest precedence first)
#   LICENSE
# Usage: fetch-grammars.sh <mac_dir> <cache_dir>
set -euo pipefail

mac_dir="$1"
cache="$2/grammar-src"
out="$mac_dir/Vendor/TreeSitterGrammars"
mkdir -p "$cache"
rm -rf "$out"
mkdir -p "$out"

checkout() {
  local repo="$1" ref="$2"
  local dir="$cache/${repo//\//__}@$ref"
  if [ ! -d "$dir/.git" ]; then
    rm -rf "$dir"
    git init -q "$dir"
    git -C "$dir" fetch -q --depth 1 "https://github.com/$repo" "$ref"
    git -C "$dir" -c advice.detachedHead=false checkout -q FETCH_HEAD
  fi
  echo "$dir"
}

# Checkout directory of another manifest row (for inherited queries).
root_of() {
  local repo ref
  read -r repo ref < <(awk -F'\t' -v id="$1" '$1 == id { print $2, $3 }' "$mac_dir/grammars.tsv")
  checkout "$repo" "$ref"
}

while IFS=$'\t' read -r id repo ref dir symbol queries; do
  case "$id" in ''|'#'*) continue ;; esac
  root="$(checkout "$repo" "$ref")"
  dest="$out/$id"
  mkdir -p "$dest/src" "$dest/include" "$dest/queries"

  cp -R "$root/$dir/src/." "$dest/src/"
  # TypeScript/TSX/PHP scanners include ../../common/scanner.h.
  if [ -d "$root/$dir/../common" ] && [ "$dir" != "." ]; then
    cp -R "$root/$dir/../common" "$dest/common"
    sed -i '' 's#"../../common/#"../common/#' "$dest/src/"*.c
  fi
  cp "$root/LICENSE" "$dest/LICENSE" 2>/dev/null || cp "$root/LICENSE.md" "$dest/LICENSE" 2>/dev/null || true

  cat > "$dest/include/grammar_$id.h" <<EOF
#pragma once
typedef struct TSLanguage TSLanguage;
const TSLanguage *tree_sitter_$symbol(void);
EOF

  : > "$dest/queries/highlights.scm"
  IFS=',' read -ra files <<< "$queries"
  for file in "${files[@]}"; do
    if [[ "$file" == *:* ]]; then
      base="$(root_of "${file%%:*}")"
      path="${file#*:}"
    else
      base="$root"
      path="$file"
    fi
    { echo "; --- $(basename "$base") $path"; cat "$base/$path"; echo; } >> "$dest/queries/highlights.scm"
  done
  echo "grammar $id ($repo $ref)"
done < "$mac_dir/grammars.tsv"

echo "$(ls "$out" | wc -l | tr -d ' ') grammars ready in apps/unshell-mac/Vendor/TreeSitterGrammars"

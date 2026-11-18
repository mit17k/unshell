
# --- Native macOS app (apps/unshell-mac) -------------------------------------

ghostty_version := "v1.4.0"
zig_version := "0.17.0"
mac_dir := justfile_directory() / "apps/unshell-mac"
mac_cache := justfile_directory() / ".cache/unshell-mac"

# Xcode owns the native toolchain. Each recipe starts with this guard: Apple's
# tools first on PATH (a Nix or Homebrew profile may ship GNU libtool, which
# rejects `-static`), and no SDKROOT/DEVELOPER_DIR pointing into /nix/store.
mac_toolchain_guard := '''export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
    case "${SDKROOT:-}" in /nix/store/*) unset SDKROOT ;; esac
    case "${DEVELOPER_DIR:-}" in /nix/store/*) unset DEVELOPER_DIR ;; esac'''

# Build GhosttyKit.xcframework from the pinned Ghostty tag (needs full Xcode)
ghostty-kit:
    #!/usr/bin/env bash
    set -euo pipefail
    {{mac_toolchain_guard}}
    mkdir -p "{{mac_cache}}"
    arch="$(uname -m)"; [ "$arch" = arm64 ] && arch=aarch64
    if command -v zig >/dev/null && [ "$(zig version)" = "{{zig_version}}" ]; then
      zig="$(command -v zig)"
    else
      zig_dir="{{mac_cache}}/zig-${arch}-macos-{{zig_version}}"
      if [ ! -x "$zig_dir/zig" ]; then
        echo "Downloading Zig {{zig_version}}"
        curl -fL "https://ziglang.org/download/{{zig_version}}/zig-${arch}-macos-{{zig_version}}.tar.xz" \
          | tar -xJ -C "{{mac_cache}}"
      fi
      zig="$zig_dir/zig"
    fi
    src="{{mac_cache}}/ghostty-{{ghostty_version}}"
    if [ ! -d "$src" ]; then
      git clone --depth 1 --branch "{{ghostty_version}}" https://github.com/ghostty-org/ghostty.git "$src"
    fi
    cd "$src"
    if ! /usr/bin/xcrun --sdk macosx metal --version >/dev/null 2>&1; then
      echo "Metal Toolchain missing; downloading it with xcodebuild"
      /usr/bin/xcodebuild -downloadComponent MetalToolchain
    fi
    "$zig" build -Doptimize=ReleaseFast -Demit-xcframework=true -Demit-macos-app=false -Dxcframework-target=native
    rm -rf "{{mac_dir}}/Vendor/GhosttyKit.xcframework" "{{mac_dir}}/Vendor/share"
    mkdir -p "{{mac_dir}}/Vendor"
    cp -R macos/GhosttyKit.xcframework "{{mac_dir}}/Vendor/"
    cp -R zig-out/share "{{mac_dir}}/Vendor/share"
    echo "GhosttyKit {{ghostty_version}} ready in apps/unshell-mac/Vendor"

# Compile the Swift app (debug by default: just mac-build release)
mac-build config="debug":
    #!/usr/bin/env bash
    set -euo pipefail
    {{mac_toolchain_guard}}
    cd "{{mac_dir}}"
    for input in Vendor/GhosttyKit.xcframework:ghostty-kit Vendor/TreeSitterGrammars:tree-sitter-grammars; do
      [ -e "${input%%:*}" ] || { echo "error: ${input%%:*} missing; run \`just ${input##*:}\` first" >&2; exit 1; }
    done
    /usr/bin/swift build -c {{config}}

# Assemble Unshell.app (binary, Info.plist, Ghostty resources, terminfo)
mac-app config="debug": (mac-build config)
    #!/usr/bin/env bash
    set -euo pipefail
    {{mac_toolchain_guard}}
    cd "{{mac_dir}}"
    bin="$(/usr/bin/swift build -c {{config}} --show-bin-path)/Unshell"
    app=".build/Unshell.app"
    rm -rf "$app"
    mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
    cp "$bin" "$app/Contents/MacOS/Unshell"
    cp Support/Info.plist "$app/Contents/Info.plist"
    cp Resources/unshell-ghostty.conf "$app/Contents/Resources/"
    # Code viewer highlight queries, one directory per grammar.
    for grammar in Vendor/TreeSitterGrammars/*/; do
      name="$(basename "$grammar")"
      mkdir -p "$app/Contents/Resources/TreeSitter/$name/queries"
      cp "$grammar/queries/highlights.scm" "$app/Contents/Resources/TreeSitter/$name/queries/"
    done
    # Dev-only sample files ship in Debug bundles only.
    if [ "{{config}}" = "debug" ]; then cp -R Resources/Samples "$app/Contents/Resources/Samples"; fi
    # libghostty finds its resources by looking for Contents/Resources/terminfo.
    cp -R Vendor/share/ghostty "$app/Contents/Resources/ghostty"
    cp -R Vendor/share/terminfo "$app/Contents/Resources/terminfo"
    /usr/bin/codesign --force --sign - "$app" >/dev/null
    echo "{{mac_dir}}/$app"

# Build and run the app in the foreground (logs to the terminal; used by `just run`)
mac-dev config="debug": (mac-app config)
    "{{mac_dir}}/.build/Unshell.app/Contents/MacOS/Unshell"

# Build and launch the app
mac-run config="debug": (mac-app config)
    #!/usr/bin/env bash
    set -euo pipefail
    {{mac_toolchain_guard}}
    /usr/bin/open "{{mac_dir}}/.build/Unshell.app"

# Launch with N terminals flooding output, to measure CPU/RAM (shown bottom-left)
mac-stress count="50" config="release": (mac-app config)
    #!/usr/bin/env bash
    set -euo pipefail
    {{mac_toolchain_guard}}
    UNSHELL_STRESS={{count}} exec "{{mac_dir}}/.build/Unshell.app/Contents/MacOS/Unshell"

# Markers are also checked against the Debug binary, so the check cannot pass
# vacuously.
# Fail if development-only code reached the release binary (native release:check)
mac-release-check: (mac-build "release") (mac-build "debug")
    #!/usr/bin/env bash
    set -euo pipefail
    {{mac_toolchain_guard}}
    cd "{{mac_dir}}"
    release="$(/usr/bin/swift build -c release --show-bin-path)/Unshell"
    debug="$(/usr/bin/swift build -c debug --show-bin-path)/Unshell"
    markers=("Development only" "DesignSystemView" "TerminalPlaygroundView" "DevWindowController" "UNSHELL_SNAPSHOT"
             "CodeViewerDevView" "CodeViewerBenchmark" "UNSHELL_CODE_BENCH" "UNSHELL_SAMPLES_DIR")
    /usr/bin/strings -a "$release" > "$TMPDIR/unshell-release.strings"
    /usr/bin/strings -a "$debug" > "$TMPDIR/unshell-debug.strings"
    status=0
    for marker in "${markers[@]}"; do
      if ! grep -qF "$marker" "$TMPDIR/unshell-debug.strings"; then
        echo "check is stale: marker '$marker' not found in the Debug binary" >&2
        status=1
      fi
      if grep -qF "$marker" "$TMPDIR/unshell-release.strings"; then
        echo "development surface leaked into release: '$marker'" >&2
        status=1
      fi
    done
    [ "$status" -eq 0 ] && echo "Release binary excludes development views and hooks (${#markers[@]} markers)."
    exit "$status"

# Fetch the code viewer's tree-sitter grammars (grammars.tsv) into Vendor/
tree-sitter-grammars:
    #!/usr/bin/env bash
    set -euo pipefail
    {{mac_toolchain_guard}}
    "{{mac_dir}}/Support/fetch-grammars.sh" "{{mac_dir}}" "{{mac_cache}}"

# Optimized build with the Debug-only benchmark compiled in (separate .build/bench).
# Reports first paint, first highlighted paint, parse, jump latency, scroll frames.
# Benchmark the code viewer on a generated file (default 50k lines)
mac-code-bench lines="50000":
    #!/usr/bin/env bash
    set -euo pipefail
    {{mac_toolchain_guard}}
    cd "{{mac_dir}}"
    /usr/bin/swift build -c release -Xswiftc -DDEBUG --scratch-path .build/bench
    UNSHELL_CODE_BENCH={{lines}} \
      UNSHELL_QUERIES_DIR="{{mac_dir}}/Vendor/TreeSitterGrammars" \
      UNSHELL_SAMPLES_DIR="{{mac_dir}}/Resources/Samples" \
      "$(/usr/bin/swift build -c release --scratch-path .build/bench --show-bin-path)/Unshell"

# Unit tests for the code viewer core (languages, highlighting, semantic tokens)
mac-test:
    #!/usr/bin/env bash
    set -euo pipefail
    {{mac_toolchain_guard}}
    cd "{{mac_dir}}"
    /usr/bin/swift test


# --- Native macOS app (apps/unshell-mac) -------------------------------------

ghostty_version := "v1.4.0"
zig_version := "0.17.0"
mac_dir := justfile_directory() / "apps/unshell-mac"
mac_cache := justfile_directory() / ".cache/unshell-mac"

# Build GhosttyKit.xcframework from the pinned Ghostty tag (needs full Xcode)
ghostty-kit:
    #!/usr/bin/env bash
    set -euo pipefail
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
    # Apple's libtool/ar/ranlib must win over GNU ones from Nix or Homebrew
    # (GNU libtool rejects `-static`).
    export PATH="/usr/bin:$PATH"
    if ! xcrun -sdk macosx metal --version >/dev/null 2>&1; then
      echo "Metal Toolchain missing; downloading it with xcodebuild"
      xcodebuild -downloadComponent MetalToolchain
    fi
    "$zig" build -Doptimize=ReleaseFast -Demit-xcframework=true -Demit-macos-app=false -Dxcframework-target=native
    rm -rf "{{mac_dir}}/Vendor/GhosttyKit.xcframework" "{{mac_dir}}/Vendor/share"
    mkdir -p "{{mac_dir}}/Vendor"
    cp -R macos/GhosttyKit.xcframework "{{mac_dir}}/Vendor/"
    cp -R zig-out/share "{{mac_dir}}/Vendor/share"
    echo "GhosttyKit {{ghostty_version}} ready in apps/unshell-mac/Vendor"

# Compile the Swift app (debug by default: just mac-build release)
mac-build config="debug":
    cd "{{mac_dir}}" && swift build -c {{config}}

# Assemble Unshell.app (binary, Info.plist, Ghostty resources, terminfo)
mac-app config="debug": (mac-build config)
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{mac_dir}}"
    bin="$(swift build -c {{config}} --show-bin-path)/Unshell"
    app=".build/Unshell.app"
    rm -rf "$app"
    mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
    cp "$bin" "$app/Contents/MacOS/Unshell"
    cp Support/Info.plist "$app/Contents/Info.plist"
    cp Resources/unshell-ghostty.conf "$app/Contents/Resources/"
    # libghostty finds its resources by looking for Contents/Resources/terminfo.
    cp -R Vendor/share/ghostty "$app/Contents/Resources/ghostty"
    cp -R Vendor/share/terminfo "$app/Contents/Resources/terminfo"
    codesign --force --sign - "$app" >/dev/null
    echo "{{mac_dir}}/$app"

# Build and launch the app
mac-run config="debug": (mac-app config)
    open "{{mac_dir}}/.build/Unshell.app"

# Launch with N terminals flooding output, to measure CPU/RAM (shown bottom-left)
mac-stress count="50" config="release": (mac-app config)
    UNSHELL_STRESS={{count}} "{{mac_dir}}/.build/Unshell.app/Contents/MacOS/Unshell"

{
  description = "Unshell TypeScript monorepo development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        # mkShellNoCC: no stdenv compiler. On macOS, Xcode owns the native
        # toolchain (clang, SDK, xcrun, Metal) for GhosttyKit, the grammars and the
        # Swift app; Nix must not inject its cc-wrapper, apple-sdk, xcrun shim,
        # SDKROOT, DEVELOPER_DIR or NIX_CFLAGS/LDFLAGS.
        # gettext provides msgfmt for GhosttyKit's translations. Zig 0.17 isn't
        # in nixpkgs yet, so `just ghostty-kit` downloads it into .cache/.
        devShells.default = pkgs.mkShellNoCC {
          packages = with pkgs; [ nodejs_24 pnpm just git gettext ];
          shellHook = ''
            # Left over from the Darwin stdenv and gettext's setup hook; only
            # Nix's cc-wrapper reads the NIX_* ones, but the deployment target
            # would reach Apple's clang and swift. Xcode decides.
            unset MACOSX_DEPLOYMENT_TARGET NIX_CFLAGS_COMPILE NIX_LDFLAGS_FOR_BUILD
            echo "Unshell development environment loaded"
            echo "Node: $(node --version)"
            echo "Run 'just' to see available commands"
          '';
        };
      });
}

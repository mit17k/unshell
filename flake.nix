{
  description = "Unshell - Electron application development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs =
            with pkgs;
            [
              # Node.js and pnpm
              nodejs_20
              pnpm

              # Build tools
              just

              # Electron dependencies (platform-specific)
            ]
            ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
              # Linux-specific dependencies for Electron
              xorg.libX11
              xorg.libXScrnSaver
              xorg.libXtst
              nss
              nspr
              alsa-lib
              cups
              libdrm
              expat
              libxkbcommon
              mesa
              pango
              cairo
              atk
              at-spi2-atk
              dbus
              gtk3
              gdk-pixbuf
              glib
            ];

          shellHook = ''
            echo "Unshell development environment loaded"
            echo "Node.js: $(node --version)"
            echo "pnpm: $(pnpm --version)"
            echo ""
            echo "Run 'just' to see available commands"
          '';
        };
      }
    );
}

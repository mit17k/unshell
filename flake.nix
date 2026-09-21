{
  description = "Unshell desktop development environment";

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
          packages =
            with pkgs;
            [
              cargo
              clippy
              just
              nodejs_24
              pnpm
              pkg-config
              rust-analyzer
              rustc
              rustfmt
            ]
            ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
              fontconfig
              freetype
              libxkbcommon
              vulkan-loader
              wayland
            ]
            ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
              libiconv
            ];

          LD_LIBRARY_PATH = pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isLinux (
            pkgs.lib.makeLibraryPath [
              pkgs.libxkbcommon
              pkgs.vulkan-loader
              pkgs.wayland
            ]
          );

          shellHook = ''
            echo "Unshell development environment loaded"
            echo "Rust: $(rustc --version)"
            echo "Node: $(node --version)"
            echo "Run 'just' to see available commands"
          '';
        };
      }
    );
}

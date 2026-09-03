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
              pkg-config
              rustc
              rustfmt
            ]
            ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
              libxkbcommon
              vulkan-loader
              wayland
            ]
            ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
              libiconv
            ];

          LD_LIBRARY_PATH = pkgs.lib.optionalString pkgs.stdenv.isLinux (
            pkgs.lib.makeLibraryPath [
              pkgs.libxkbcommon
              pkgs.vulkan-loader
              pkgs.wayland
            ]
          );

          shellHook = ''
            echo "Unshell development environment loaded"
            echo "Rust: $(rustc --version)"
            echo "Run 'just' to see available commands"
          '';
        };
      }
    );
}

{
  description = "Unshell development shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        node = pkgs.nodejs_24;
      in {
        devShells.default = pkgs.mkShell {
          packages = [ node pkgs.pnpm pkgs.just pkgs.git ];
          shellHook = ''
            export ELECTRON_SKIP_BINARY_DOWNLOAD=1
            echo "node ${node.version}"
          '';
        };
      });
}

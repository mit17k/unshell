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
        devShells.default = pkgs.mkShell ({
          packages = with pkgs; [ nodejs_24 pnpm just git ];
          shellHook = ''
            echo "Unshell development environment loaded"
            echo "Node: $(node --version)"
            echo "Run 'just' to see available commands"
          '';
        } // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          ELECTRON_OVERRIDE_DIST_PATH = "${pkgs.electron}/lib/electron";
        });
      });
}

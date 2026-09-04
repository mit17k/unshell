{ pkgs }:

pkgs.mkShell {
  packages = import ./tools.nix { inherit pkgs; };
}

{
  description = "Prebuilt third-party packages, served via Cachix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
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

        packageNames = map (name: builtins.substring 0 (builtins.stringLength name - 4) name) (
          builtins.filter (name: builtins.match ".+\\.nix" name != null) (
            builtins.attrNames (builtins.readDir ./packages)
          )
        );
      in
      {
        packages = builtins.listToAttrs (
          map (name: {
            name = name;
            value = import (./packages + "/${name}.nix") pkgs;
          }) packageNames
        );
      }
    );
}

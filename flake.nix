{
  description = "Prebuilt third-party packages, served via Cachix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
    windinput.url = "github:huanfeng/WindInput";
    # Match the main flake's nixpkgs so the fcitx5 ABI lines up.
    windinput.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      windinput,
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
        packages =
          builtins.listToAttrs (
            map (name: {
              name = name;
              value = import (./packages + "/${name}.nix") pkgs;
            }) packageNames
          )
          // {
            # WindInput ships its own flake with a NixOS/fcitx5 package.
            windinput = windinput.packages.${system}.windinput;
          };
      }
    );
}

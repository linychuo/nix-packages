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
            #
            # Two patches on top of it:
            #
            # 1. fontconfig encodes a variable-font TTC face as
            #    `(instance << 16) | face_index` (Noto Sans CJK SC Regular =
            #    262146), while ttf_parser::Face::parse wants the plain face
            #    index. Unmasked, every CJK face fails to load and the candidate
            #    window draws blank. The service (where wind-ui lives) is rebuilt
            #    with the mask.
            # 2. The addon conf does not declare a dependency on the `wayland`
            #    module, so fcitx5 may load windinput first; WaylandCandidatePanel
            #    then looks up `wayland` once, finds nothing and permanently
            #    disables the Wayland candidate window. Declare the dependency so
            #    the module is there before the addon is constructed.
            #
            # The addon is rebuilt against the patched service because it bakes
            # the service's store path at configure time.
            windinput =
              let
                upstream = windinput.packages.${system};
                src = windinput.outPath;
                version = nixpkgs.lib.removeSuffix "\n" (builtins.readFile (src + "/docs/VERSION"));
                patchedService = upstream.windinput-service.overrideAttrs (old: {
                  postPatch = (old.postPatch or "") + ''
                    substituteInPlace crates/wind-ui/src/text/linux/fontconfig.rs --replace-fail 'index: index.max(0) as u32,' 'index: (index.max(0) as u32) & 0xffff,'
                  '';
                });
                patchedAddon =
                  let
                    base = pkgs.callPackage (src + "/wind_linux/nix/addon.nix") {
                      inherit version;
                      service = patchedService;
                      setting = upstream.wind-setting;
                    };
                  in
                  base.overrideAttrs (old: {
                    postInstall = (old.postInstall or "") + ''
                      printf '\n[Addon/Dependencies]\n0=wayland:${pkgs.fcitx5.version}\n' >> $out/share/fcitx5/addon/windinput.conf
                    '';
                  });
              in
              pkgs.callPackage (src + "/wind_linux/nix/package.nix") {
                inherit version;
                windinput-service = patchedService;
                windinput-fcitx5 = patchedAddon;
                wind-setting = upstream.wind-setting;
              };
          };
      }
    );
}

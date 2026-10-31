# nix-packages

Prebuilt third-party packages that have no upstream flake and are not in
nixpkgs. Each package is built by CI and pushed to a Cachix cache, so the
local machine can pull the prebuilt store path instead of building it.

## Layout

```
flake.nix                  # auto-discovers every packages/*.nix
packages/
  openidea.nix             # openidea: wraps the official release .deb
.github/workflows/build.yml
```

Adding a package: drop a `packages/<name>.nix` that takes `pkgs` and returns
a derivation. It is picked up automatically.

## CI

`.github/workflows/build.yml` runs daily at 06:00 UTC and on manual dispatch:

1. Fetches the latest `l0ng-ai/openidea` release tag.
2. If it differs from the pinned `version`, recomputes the `.deb` hash,
   updates `packages/openidea.nix`, and commits + pushes.
3. Builds `packages.x86_64-linux.openidea`.
4. Pushes the whole closure (`nix path-info -r`) to Cachix.

Required repository configuration:

| Type | Name | Value |
|---|---|---|
| Variable | `CACHIX_CACHE` | Cachix cache name, e.g. `ivannix` |
| Secret | `CACHIX_AUTH_TOKEN` | Cachix write token |

Manual dispatch always builds, so the first run seeds the cache even when the
version is already current.

## Local usage

Add the cache as a substituter (NixOS):

```nix
nix.extraOptions = ''
  extra-substituters = https://<cache>.cachix.org
  extra-trusted-public-keys = <cache>-1:<public-key>
'';
```

Then consume the package:

```nix
inputs.nix-packages.url = "github:linychuo/nix-packages";
# ...
home.packages = [ inputs.nix-packages.packages.x86_64-linux.openidea ];
```

Update to a new upstream release:

```sh
nix flake update nix-packages
sudo nixos-rebuild switch --flake .#ivan
```

> Cache hits require the nixpkgs revision to match the one CI used. When
> bumping nixpkgs locally, bump it in this repo too (or expect one local
> rebuild after the channel moves).

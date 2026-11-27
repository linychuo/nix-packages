pkgs:

# Nordwand Mono, Nerd Font variant ("Nerdwand Mono") — a compact
# neo-grotesque monospace face. Only the four weights we actually use are
# installed; the release zip ships 18.
let
  pname = "nerdwand-mono";
  version = "1.6.0";
in
pkgs.stdenvNoCC.mkDerivation {
  inherit pname version;

  src = pkgs.fetchzip {
    url = "https://github.com/tywr/Nordwand-Mono/releases/download/${version}/NerdwandMono-OTF.zip";
    hash = "sha256-kWQfPdGUxL2C2x1vR8EPtM9Iz+Cm7uzF0wlSv7+dVlQ=";
    # The zip is a flat list of font files (plus a licenses/ dir), not a
    # single top-level directory.
    stripRoot = false;
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/fonts/nerdwand-mono
    for f in Regular Bold Italic BoldItalic; do
      install -m444 -t $out/share/fonts/nerdwand-mono "NerdwandMono-$f.otf"
    done
    runHook postInstall
  '';
}

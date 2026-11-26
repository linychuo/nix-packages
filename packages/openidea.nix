pkgs:

let
  pname = "openidea";
  version = "0.1.53";
in
pkgs.stdenv.mkDerivation {
  inherit pname version;

  src = pkgs.fetchurl {
    url = "https://github.com/l0ng-ai/openidea/releases/download/v${version}/OpenIDEA_${version}_amd64.deb";
    hash = "sha256-oTs7pXSs7j4p0Ot5eDzKxQIk+Q+Ufa1AhozY94xBaCs=";
  };

  nativeBuildInputs = with pkgs; [
    dpkg
    autoPatchelfHook
    wrapGAppsHook3
    makeWrapper
  ];

  buildInputs = with pkgs; [
    gtk3
    webkitgtk_4_1
    gdk-pixbuf
    cairo
    dbus
    libsoup_3
  ];

  unpackPhase = "dpkg-deb -x $src $PWD";

  installPhase = ''
    runHook preInstall

    install -Dm755 usr/bin/openidea $out/bin/openidea
    install -Dm644 usr/share/applications/OpenIDEA.desktop \
      $out/share/applications/OpenIDEA.desktop

    mkdir -p $out/share/icons/hicolor
    cp -r usr/share/icons/hicolor/. $out/share/icons/hicolor/

    runHook postInstall
  '';
}

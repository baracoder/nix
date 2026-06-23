{
  pkgs,
  stdenv,
  nixosTests,
}:
let

  pname = "gnome-shell-extension-baracoder-tts";
  version = "git";
  uuid = "tts@baracoder";
in
stdenv.mkDerivation {
  inherit pname version;
  src = ./src;
  nativeBuildInputs = with pkgs; [ buildPackages.glib ];
  buildPhase = ''
    runHook preBuild
    if [ -d schemas ]; then
      glib-compile-schemas --strict schemas
    fi
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/gnome-shell/extensions/
    cp -r -T . $out/share/gnome-shell/extensions/tts@baracoder
    runHook postInstall
  '';
  passthru = {
    extensionPortalSlug = pname;
    extensionUuid = uuid;

    tests = {
      gnome-extensions = nixosTests.gnome-extensions;
    };
  };
}

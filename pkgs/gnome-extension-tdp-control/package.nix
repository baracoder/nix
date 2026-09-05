{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  glib,
  nixosTests,
}:

# Third-party alternative to the self-rolled tdp@baracoder extension. Same
# quick-settings idea, but it drives steamos-manager (steamosctl) over D-Bus,
# so it needs the steamos-manager package installed alongside it.
let
  uuid = "tdp-control@opengamingcollective.org";
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "gnome-shell-extension-tdp-control";
  version = "1-unstable-2026-09-02";

  src = fetchFromGitHub {
    owner = "OpenGamingCollective";
    repo = "gnome-shell-extension-tdp-control";
    rev = "40f5ce389d430dff1473be703dca590a28001e4b";
    hash = "sha256-oulj16qPQdE1YcKaffIepzgQMt45psJ/9STcMUJJ4So=";
  };

  nativeBuildInputs = [ glib ];

  buildPhase = ''
    runHook preBuild
    glib-compile-schemas --strict schemas
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/gnome-shell/extensions
    cp -r -T . $out/share/gnome-shell/extensions/${uuid}
    runHook postInstall
  '';

  passthru = {
    extensionPortalSlug = finalAttrs.pname;
    extensionUuid = uuid;

    tests = {
      gnome-extensions = nixosTests.gnome-extensions;
    };
  };

  meta = {
    description = "GNOME quick settings toggle for performance profiles, TDP limit and GPU clock via steamos-manager";
    homepage = "https://github.com/OpenGamingCollective/gnome-shell-extension-tdp-control";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
})

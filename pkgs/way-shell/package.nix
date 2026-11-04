{
  lib,
  stdenv,
  fetchFromGitHub,
  pkg-config,
  glib,
  wayland-scanner,
  wrapGAppsHook4,
  gtk4,
  gtk4-layer-shell,
  json-glib,
  libadwaita,
  libpulseaudio,
  networkmanager,
  pipewire,
  upower,
  wayland,
  wayland-protocols,
  wireplumber,
}:

stdenv.mkDerivation {
  pname = "way-shell";
  version = "0-unstable-2026-02-21";

  src = fetchFromGitHub {
    owner = "ldelossa";
    repo = "way-shell";
    rev = "96b7dd9487e19961d28f1efeb745a49740e295f6";
    hash = "sha256-qAGhlkquiByrVq5Z0pXNzY0XoEOB9eCyaGm1d9Nv3q0=";
  };

  # Upstream only drives Sway and niri; this adds IonWL, picked
  # automatically in an IonWL session.
  patches = [ ./ionwl-backend.patch ];

  nativeBuildInputs = [
    pkg-config
    glib
    wayland-scanner
    wrapGAppsHook4
  ];

  buildInputs = [
    gtk4
    gtk4-layer-shell
    json-glib
    libadwaita
    libpulseaudio
    networkmanager
    pipewire
    upower
    wayland
    wayland-protocols
    wireplumber
  ];

  # wireplumber_service.c includes pipewire headers, which the Makefile does
  # not ask pkg-config for.
  env.NIX_CFLAGS_COMPILE = toString [
    "-I${lib.getDev pipewire}/include/pipewire-0.3"
    "-I${lib.getDev pipewire}/include/spa-0.2"
  ];

  makeFlags = [
    "PREFIX=${placeholder "out"}"
    "CC=${stdenv.cc.targetPrefix}cc"
  ];

  # glib's setup hook moves the schema to the gsettings-schemas directory
  # wrapGAppsHook4 points at, but leaves compiling it to the package.
  installFlags = [ "SCHEMADIR=${placeholder "out"}/share/glib-2.0/schemas" ];

  preFixup = ''
    glib-compile-schemas $out/share/gsettings-schemas/$name/glib-2.0/schemas
  '';

  postInstall = ''
    substituteInPlace $out/lib/systemd/user/way-shell.service \
      --replace-fail /usr/bin/way-shell $out/bin/way-shell
  '';

  meta = {
    description = "GNOME-inspired desktop shell for Wayland compositors";
    homepage = "https://github.com/ldelossa/way-shell";
    license = lib.licenses.gpl2Only;
    mainProgram = "way-shell";
    platforms = lib.platforms.linux;
  };
}

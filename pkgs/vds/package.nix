{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  bluez,
  dbus,
  libopus,
  udev,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "vds";
  version = "0.4.0-rc1";

  src = fetchFromGitHub {
    owner = "hurryman2212";
    repo = "vds";
    tag = finalAttrs.version;
    hash = "sha256-Lw+CUzRKYGYLyy0rfphFXaWKSYpPS6mnuKDHnDu48/w=";
  };

  # The version comes from `git describe`, which the tarball has no .git for.
  postPatch = ''
    printf '#!/bin/sh\necho %s\n' '${finalAttrs.version}' > generate-version.sh
    chmod +x generate-version.sh
    patchShebangs generate-version.sh
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    bluez
    dbus
    libopus
    udev
  ];

  # The systemd unit lives in the NixOS module; ship the udev and WirePlumber
  # rules so the module can pick them up through udev.packages/configPackages.
  postInstall = ''
    install -Dm644 $src/99-vds-dualsense-udev.rules \
      $out/lib/udev/rules.d/99-vds-dualsense.rules
    install -Dm644 $src/99-vds-dualsense-wireplumber.conf \
      $out/share/wireplumber/wireplumber.conf.d/99-vds-dualsense.conf
  '';

  meta = {
    description = "Virtual USB DualSense bridge for Bluetooth-connected DualSense controllers";
    homepage = "https://github.com/hurryman2212/vds";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "vdsctl";
  };
})

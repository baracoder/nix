{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  glib,
  speechd,
  udev,
}:

# The OpenGamingCollective fork of Valve's steamos-manager. Its addition over
# upstream is a native PowerStation TDP backend (TdpLimitingMethod::PowerStation)
# plus device entries that use it -- including G1619-05, this machine. That is
# what Terra ships as "steamos-manager-powerstation": the same source, built
# with Provides/Conflicts against the stock steamos-manager rather than a
# separate program. Pinned to the commit Terra packaged.
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "steamos-manager";
  version = "0-unstable-2026-08-23";

  src = fetchFromGitHub {
    owner = "OpenGamingCollective";
    repo = "steamos-manager";
    rev = "25bff4c18dc646570915186d08ebaeb0c14c001f";
    hash = "sha256-kFqbUk46qKtCEvOmmgOqsLRZbxtf/5rwaVDWjeHhpQk=";
  };

  cargoHash = "sha256-JN4cRQAgNReItzH1zqP3/tPnXZPJi/0VkP2C1fB6RcM=";

  # The data paths are compile-time constants pointing at /usr/share, with no
  # XDG lookup to fall back on. /etc/steamos-manager is left alone: that one is
  # a real config location. The remaining hits are all in #[cfg(test)] code.
  postPatch = ''
    substituteInPlace \
      steamos-manager/src/hardware.rs \
      steamos-manager/src/platform.rs \
      steamos-manager/src/daemon/user.rs \
      steamos-manager/src/daemon/root.rs \
      --replace-warn /usr/share/steamos-manager $out/share/steamos-manager
  '';

  nativeBuildInputs = [
    pkg-config
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    glib
    speechd
    udev
  ];

  # Most of the suite wants a live system: /dev/cec*, a session bus, real DMI.
  # The fork also left hardware::test::board_lookup_invalid asserting the
  # pre-fork "unknown" fallback, which its own generic.toml now resolves to
  # "generic" instead.
  doCheck = false;

  # The upstream Makefile installs from target/release, which is not where
  # buildRustPackage puts things, so mirror its install rules instead.
  postInstall = ''
    # The daemon is not on PATH upstream either; only steamosctl is.
    install -D -m755 $out/bin/steamos-manager $out/lib/steamos-manager
    rm $out/bin/steamos-manager

    install -D -m644 -t $out/share/steamos-manager/devices data/devices/*
    install -D -m644 data/platform.toml $out/share/steamos-manager/platform.toml
    install -D -m644 -t $out/share/dbus-1/interfaces data/interfaces/*

    install -D -m644 data/system/com.steampowered.SteamOSManager1.service \
      $out/share/dbus-1/system-services/com.steampowered.SteamOSManager1.service
    install -D -m644 data/system/com.steampowered.SteamOSManager1.conf \
      $out/share/dbus-1/system.d/com.steampowered.SteamOSManager1.conf
    install -D -m644 data/user/com.steampowered.SteamOSManager1.service \
      $out/share/dbus-1/services/com.steampowered.SteamOSManager1.service

    install -D -m644 data/system/steamos-manager.service \
      $out/lib/systemd/system/steamos-manager.service
    for unit in steamos-manager steamos-manager-session-cleanup steamos-manager-configure-cecd; do
      install -D -m644 "data/user/$unit.service" "$out/lib/systemd/user/$unit.service"
    done

    # The units hardcode Fedora install locations: the daemon for the two
    # that run it, steamosctl for the two oneshots.
    substituteInPlace \
      $out/lib/systemd/system/steamos-manager.service \
      $out/lib/systemd/user/steamos-manager.service \
      --replace-fail /usr/lib/steamos-manager $out/lib/steamos-manager
    substituteInPlace \
      $out/lib/systemd/user/steamos-manager-session-cleanup.service \
      $out/lib/systemd/user/steamos-manager-configure-cecd.service \
      --replace-fail /usr/bin/steamosctl $out/bin/steamosctl
  '';

  meta = {
    description = "System daemon abstracting Steam's interactions with the OS, with PowerStation TDP support";
    homepage = "https://github.com/OpenGamingCollective/steamos-manager";
    license = lib.licenses.mit;
    mainProgram = "steamosctl";
    platforms = lib.platforms.linux;
  };
})

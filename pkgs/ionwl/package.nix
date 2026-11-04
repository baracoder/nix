{
  lib,
  rustPlatform,
  runtimeShell,
  fetchgit,
  pkg-config,
  makeWrapper,
  python3,
  fontconfig,
  libdisplay-info_0_3,
  libdrm,
  libgbm,
  libglvnd,
  libinput,
  libxkbcommon,
  seatd,
  systemdLibs,
  wayland,
  xwayland,
  libx11,
  libxcursor,
  libxi,
}:

rustPlatform.buildRustPackage {
  pname = "ionwl";
  version = "0.1.0-unstable-2026-11-04";

  src = fetchgit {
    url = "https://codeberg.org/ideasman42/ionwl.git";
    rev = "7ef31c864ab41f59a6a27353c4a0075f58dabead";
    hash = "sha256-x991n0K2pB3SkpzCVdZmR2/cvJeRiDlsw3cSpVsiO6E=";
  };

  # Upstream does not commit a lockfile.
  cargoLock = {
    lockFile = ./Cargo.lock;
    allowBuiltinFetchGit = true;
  };

  # IONWL_PRIMARY_GPU picks the render GPU when smithay guesses wrong, and
  # the DMA-BUF global comes from it rather than the first GPU found.
  patches = [ ./primary-gpu-override.patch ];

  postPatch = ''
    ln -s ${./Cargo.lock} Cargo.lock
  '';

  nativeBuildInputs = [
    pkg-config
    makeWrapper
    python3
  ];

  buildInputs = [
    fontconfig
    libdisplay-info_0_3
    libdrm
    libgbm
    libglvnd
    libinput
    libxkbcommon
    python3
    seatd
    systemdLibs
    wayland
  ];

  # Upstream denies all rustc warnings; don't fail on ones a newer rustc adds.
  env.CARGO_BUILD_WARNINGS = "warn";
  env.PYO3_PYTHON = "${python3}/bin/python3";

  # Integration tests need a running compositor.
  doCheck = false;

  postInstall = ''
    # Data dir is located relative to the binary (<exe>/../share/ionwl).
    mkdir -p $out/share
    cp -r share/ionwl $out/share/ionwl
    find $out/share/ionwl -type d -name __pycache__ -exec rm -rf {} +
    install -Dm644 config/default/ion_init.py $out/share/ionwl/config/default/ion_init.py

    # Without a config there are no keybindings at all, so the session
    # seeds the upstream default on first start.
    cat > $out/bin/ionwl-session <<EOF
    #!${runtimeShell}
    config="\''${XDG_CONFIG_HOME:-\$HOME/.config}/ionwl/ion_init.py"
    if [ ! -e "\$config" ]; then
      install -Dm644 $out/share/ionwl/config/default/ion_init.py "\$config"
    fi
    exec $out/bin/ionwl "\$@"
    EOF
    chmod +x $out/bin/ionwl-session

    install -Dm644 share/wayland-sessions/ionwl.desktop $out/share/wayland-sessions/ionwl.desktop
    substituteInPlace $out/share/wayland-sessions/ionwl.desktop \
      --replace-fail "Exec=ionwl" "Exec=$out/bin/ionwl-session"
  '';

  # EGL, wayland and xkb are dlopen'ed at runtime.
  postFixup = ''
    wrapProgram $out/bin/ionwl \
      --prefix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath [
          libglvnd
          libxkbcommon
          wayland
          libxcursor
          libxi
          libx11
        ]
      } \
      --prefix PATH : ${lib.makeBinPath [ xwayland ]}
  '';

  passthru.providedSessions = [ "ionwl" ];

  meta = {
    description = "Manual tiling Wayland compositor inspired by Ion3";
    homepage = "https://codeberg.org/ideasman42/ionwl";
    license = lib.licenses.gpl3Plus;
    mainProgram = "ionwl";
    platforms = lib.platforms.linux;
  };
}

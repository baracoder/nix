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
  patches = [
    ./primary-gpu-override.patch
    # Touchpads were only detected via libinput's touch capability, which
    # only touchscreens have, so they got mouse prefs instead.
    ./touchpad-detection.patch
    # Idle notifications for clients (swayidle, shells' idle timers).
    ./ext-idle-notify.patch
    # MatchPointer(btn.WHEEL_UP / WHEEL_DOWN / ...) binds wheel detents.
    ./wheel-bindings.patch
    # Workspace lists and switching for bars (dux-shell, waybar).
    ./ext-workspace.patch
    # Games can opt out of vsync; needs the smithay patch below.
    ./tearing-control.patch
    # Touchpad swipe/pinch/hold reach clients.
    ./pointer-gestures.patch
    # ion.app.hooks.xwayland_ready_post, to export DISPLAY to the session.
    ./xwayland-ready-hook.patch
    # window_drag / frame_resize_drag: Super+drag moves a tiled window to
    # another frame, or resizes it by its nearest dividers.
    ./tiled-drag.patch
    # Swipes with gesture_swipe_fingers fingers, on a touchpad or touchscreen,
    # switch desktops.
    ./desktop-swipe.patch
    # Fullscreen windows cover Top-layer bars, as layer-shell intends.
    ./fullscreen-covers-top-layer.patch
  ];

  # Async page flips in smithay's DrmCompositor, a backport of the unmerged
  # Smithay/smithay#1948. Git deps are vendored without checksums, so the
  # vendored copy can be patched in place.
  postPatch = ''
    ln -s ${./Cargo.lock} Cargo.lock
    smithay=$(echo "$cargoDepsCopy"/smithay-[0-9]*)
    chmod -R u+w "$smithay"
    patch -d "$smithay" -p1 < ${./smithay-drm-async-page-flip.patch}
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

  # EGL, wayland, xkb and the X11 libs are dlopen'ed at runtime. They go in
  # the RPATH rather than LD_LIBRARY_PATH, which every program ionwl starts
  # (the shell, and the apps it launches) would inherit.
  postFixup = ''
    patchelf --add-rpath ${
      lib.makeLibraryPath [
        libglvnd
        libxkbcommon
        wayland
        libxcursor
        libxi
        libx11
      ]
    } $out/bin/ionwl
    wrapProgram $out/bin/ionwl \
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

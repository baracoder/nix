# From https://github.com/Mic92/nix-ld/pull/31/files
{pkgs, config, lib, ...}:
let
  cfg = config.programs.nix-ld;

  # TODO make glibc here configureable?
  nix-ld-so = pkgs.runCommand "ld.so" {} ''
    ln -s "$(cat '${pkgs.stdenv.cc}/nix-support/dynamic-linker')" $out
  '';

  nix-ld-libraries = pkgs.buildEnv {
    name = "lb-library-path";
    pathsToLink = [ "/lib" ];
    paths = map lib.getLib cfg.libraries;
    extraPrefix = "/share/nix-ld";
    ignoreCollisions = true;
  };

  # Libraries needed for python wheels?
  baseLibraries = with pkgs; [
    zlib
    stdenv.cc.cc
    curl
  ];

  desktopLibraries = [
    # contain all dependencies of an electron-based application
  ];

  libraries = with pkgs; [
    fuse3
    alsa-lib
    at-spi2-atk
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk2
    gtk3
    libGL
    libappindicator-gtk3
    libdrm
    libnotify
    libpulseaudio
    libuuid
    libxkbcommon
    mesa
    nspr
    nss
    pango
    pipewire
    systemd
    xorg.libX11
    xorg.libXScrnSaver
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst
    xorg.libxkbfile
    xorg.libxshmfence
    xorg.libXft
    xorg.libxcb
    zlib
    (lib.lowPrio ncurses5) # xgdb from xilinx vitis
    ncurses
    lzma
  ];
in
{
  options = {
    programs.nix-ld = {
      #enable = lib.mkEnableOption "nix-ld";

      libraries = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        description = "Libraries that automatically become available to all programs. The default set includes common libraries.";
        default = baseLibraries;
      };

      baseLibraries = lib.mkOption {
        type = lib.types.listOf lib.types.package;
	readOnly = true;
        description = "<TODO>.";
        default = baseLibraries;
      };

      desktopLibraries = lib.mkOption {
        type = lib.types.listOf lib.types.package;
	readOnly = true;
        description = "<TODO>.";
        default = desktopLibraries;
      };
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.packages = [
      (pkgs.callPackage ../nix-ld.nix {})
    ];

    environment.systemPackages = [ nix-ld-libraries ];

    environment.pathsToLink = [ "/share/nix-ld" ];

    environment.variables = {
       NIX_LD = toString nix-ld-so;
       NIX_LD_LIBRARY_PATH = "/run/current-system/sw/share/nix-ld/lib";
     };
  };

}
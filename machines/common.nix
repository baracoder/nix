# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:
{
  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes ca-derivations repl-flake
    '';
    settings = {
      trusted-users = [ "root" "@wheel" ];
      substituters = [
        "https://cache.nixos.org/"
        "https://all-hies.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "all-hies.cachix.org-1:JjrzAOEUsD9ZMt8fdFbzo3jNAyEWlPAwdVuHw4RD43k="
      ];

    };
    gc = {
      options = "--delete-older-than 30d";
    };
  };
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [ ];

  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;

  hardware.ksm.enable = true;

  console.font = "Lat2-Terminus16";
  console.keyMap = "us";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "de_DE.UTF-8/UTF-8"
  ];

  time.timeZone = "Europe/Berlin";

  documentation.man.generateCaches = false;

  hardware.sane.enable = true;

  fonts = {
    enableDefaultPackages = true;
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    fontconfig = {
      enable = true;
      allowBitmaps = true;
    };
    packages = with pkgs; [
      terminus_font
      terminus_font_ttf
      corefonts
      inconsolata
      ubuntu_font_family
      unifont
      twemoji-color-font
      (nerdfonts.override { fonts = [ "SourceCodePro" "FiraCode" "DroidSansMono" "DejaVuSansMono" "Terminus" ]; })
    ];
  };

  hardware.pulseaudio = {
    enable = false;
    support32Bit = true;
    package = pkgs.pulseaudioFull;
  };

  xdg.autostart.enable = true;
  xdg.portal = {
    xdgOpenUsePortal = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
     ];
    enable = true;
  };

  services.pipewire = {
    enable = true;
    wireplumber.enable = true;
    pulse.enable = true;
    jack.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };
  # Workaround for HDML & USB sound delayed start
  # From https://wiki.archlinux.org/title/PipeWire#Noticeable_audio_delay_or_audible_pop/crack_when_starting_playback
  environment.etc."wireplumber/main.lua.d/51-disable-suspend.lua".text = ''
    table.insert (alsa_monitor.rules, {
      matches = {
        {
          -- Matches all sources.
          { "node.name", "matches", "alsa_input.*" },
        },
        {
          -- Matches all sinks.
          { "node.name", "matches", "alsa_output.*" },
        },
      },
      apply_properties = {
        ["session.suspend-timeout-seconds"] = 0,  -- 0 disables suspend
      },
    })
  '';

  security.rtkit.enable = true;
  services.smartd.enable = true;

  services.envfs.enable = true;

  services = {
    flatpak.enable = true;
    avahi = {
      enable = true;
      nssmdns = true;
    };
    resolved = {
      enable = true;
      fallbackDns = [ "" ];
    };
    openssh.enable = true;
    openssh.settings.X11Forwarding = true;
    udisks2.enable = true;
    printing.enable = true;
    printing.drivers = with pkgs; [ gutenprint brlaser brgenml1lpr brgenml1cupswrapper hplip ];
    xserver =
    let xkbVariant = "altgr-intl"; # no dead keys
        xkbOptions = "eurosign:e,compose:menu,lv3:caps_switch";
    in {
      inherit xkbVariant xkbOptions;

      enable = true;
      layout = "us";
      exportConfiguration = true;

      displayManager = {
        gdm = {
          enable = true;
        };
        autoLogin = {
          enable = false;
          user = "bara";
        };
        defaultSession = "hyprland";
      };
      desktopManager.gnome = {
        enable = false; # Not compatible with hyprland
        extraGSettingsOverrides = ''
          [org.gnome.desktop.input-sources]
          sources=[('xkb', '${xkbVariant}')]
          xkb-options=['${xkbOptions}']
        '';
      };
    };
  };

  services.blueman.enable = true;
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
  };
  networking.networkmanager.enable = true;
  security.pam.services.gtklock = {};
  qt.style = "adwaita-dark";
  environment.etc = {
    "xdg/gtk-3.0/settings.ini".text = ''
      [Settings]
      gtk-application-prefer-dark-theme=1
    '';
    "xdg/gtk-4.0/settings.ini".text = ''
      [Settings]
      gtk-application-prefer-dark-theme=1
    '';
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.bara = {
    isNormalUser = true;
    uid = 1000;
    group = "bara";
    extraGroups = [ "dialout" "scanner" "avahi" "users" "video" "wheel" "adm" "audio" "docker" "input" "vboxusers" "adbusers" "libvirtd" "plugdev" ];
    createHome = true;
    shell = pkgs.zsh;
  };
  users.extraGroups.bara.gid = 1000;

  services.udev.packages = with pkgs; [
    openhantek6022
  ];

  systemd.packages = with pkgs; [
    swayosd
  ];

  environment.systemPackages = with pkgs; [
    # hyprland related
    fuzzel
    networkmanagerapplet
    polybarFull
    playerctl
    gsettings-desktop-schemas
    nwg-bar
    nwg-dock
    nwg-panel
    nwg-drawer
    nwg-displays
    gtklock
    gtklock-userinfo-module
    gtklock-powerbar-module
    gtklock-playerctl-module
    wlr-randr
    swaynotificationcenter
    lxappearance
    gsettings-desktop-schemas
    gnome.adwaita-icon-theme
    gtk3
    blueman
    swayidle
    gopsuinfo
    swayosd
    gnome.nautilus
    xfce.thunar
    flameshot
    grim
    slurp
    swappy
    wl-clipboard

    aspell
    aspellDicts.de
    aspellDicts.en
    avahi
    cifs-utils
    curl
    docker
    docker-compose
    dosfstools
    espeak
    ((emacsPackagesFor emacs29).emacsWithPackages (epkgs: with epkgs; [
      vterm
      sqlite
      sqlite3
      emacsql-sqlite
    ]))
    emote
    unzip
    evince
    direnv
    delta
    dmenu
    dogdns
    file
    foot
    gimp
    gitAndTools.gitFull
    gitflow
    git-lfs
    gitg
    glab
    gnumake
    gnome-console
    gnome-usage
    google-chrome
    google-cloud-sdk
    gnome.gnome-tweaks
    gsmartcontrol
    hdparm
    hyprpaper
    btop
    htop
    imagemagick
    iotop
    lm_sensors
    meld
    mellowplayer
    mumble
    mtools
    nmap
    nodejs-18_x
    ntfs3g
    nvme-cli
    octave
    openhantek6022
    pamixer
    pass
    pciutils
    #peek
    pavucontrol
    pdfgrep
    pinentry_gnome
    pre-commit
    pwgen
    python3
    qjackctl
    remmina
    renameutils
    ripgrep
    robo3t
    source-code-pro
    gnome.gnome-boxes
    gnome.ghex
    spice-gtk
    speechd
    sshfs-fuse
    sqlite
    vlc
    wget
    fzf
    fd
    tldr
    usbutils
    zsh
    samba
    virt-manager
    wireguard-tools
    wireshark
    xpra
    nix-tree
    yaml-language-server
    (callPackage ../pkgs/vscode.nix {})
    # Broken https://github.com/NixOS/nixpkgs/pull/172335
    (callPackage ../pkgs/dotnetSdk.nix {})
    (callPackage ../pkgs/lens.nix {})
    (callPackage ../pkgs/vim.nix {})
  ] ++ (with gnomeExtensions; [
    appindicator
    bing-wallpaper-changer
    bluetooth-quick-connect
    emoji-selector
    system-monitor
    tiling-assistant
    (gesture-improvements.overrideAttrs (a: {
      postInstall = ''
        sed -i 's/"42"/"43"/' $out/share/gnome-shell/extensions/gestureImprovements@gestures/metadata.json
      '';
    }))
  ]) ++ (with fishPlugins; [ done forgit fzf-fish tide ]);

  hardware.openrazer = {
    enable = true;
    users = [ "bara" ];
  };

  services.gvfs.enable = true;
  services.fwupd.enable = true;
  services.gnome = {
    gnome-browser-connector.enable = true;
    gnome-keyring.enable = true;
    gnome-online-accounts.enable = true;
    gnome-online-miners.enable = true;
    #gnome-user-share.enable = true;
    tracker-miners.enable = true;
    tracker.enable = true;
    sushi.enable = true;
    at-spi2-core.enable = true;
  };

  services.earlyoom.enable = true;

  programs.firefox = {
    enable = true;
    languagePacks = [ "en-US" "de" ];
  };
  programs.seahorse.enable = true;
  programs.gnome-terminal.enable = true;
  programs.gnome-disks.enable = true;
  programs.gnupg.agent = {
    enable = true;
    pinentryFlavor = "gnome3";
  };
  services.pcscd.enable = true;

  programs.adb.enable = true;
  programs.bash.enableCompletion = true;
  programs.zsh.enable = true;
  programs.fish.enable = true;

  programs.nix-ld.enable = true;

  # raise limit to avoid steamplay problems
  systemd.extraConfig = "DefaultLimitNOFILE=1048576";

  # directly run the missing commands via nix-shell (without installing anything)
  programs.command-not-found.enable = true;
  environment.variables.NIX_AUTO_RUN = "1";
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  hardware.bluetooth.enable = true;
  hardware.logitech.wireless.enable = true;
  hardware.logitech.wireless.enableGraphical = true;

  virtualisation.spiceUSBRedirection.enable = true;

  nyris.programs.enable = true;
}

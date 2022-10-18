# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
{
  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes ca-derivations
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



  fonts = {
    enableDefaultFonts = true;
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    fontconfig = {
      enable = true;
      allowBitmaps = true;
    };
    fonts = with pkgs; [
      terminus_font
      terminus_font_ttf
      corefonts
      inconsolata
      ubuntu_font_family
      unifont
      twemoji-color-font
      nerdfonts
    ];
  };

  hardware.pulseaudio = {
    enable = false;
    support32Bit = true;
    package = pkgs.pulseaudioFull;
  };

  services.packagekit.enable = true;

  services.pipewire = {
    enable = true;
    wireplumber.enable = true;
    pulse.enable = true;
    jack.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };
  security.rtkit.enable = true;
  services.smartd.enable = true;

  services = {
    flatpak.enable = true;
    avahi = {
      enable = true;
      nssmdns = true;
    };
    resolved.enable = true;
    openssh.enable = true;
    openssh.forwardX11 = true;
    udisks2.enable = true;
    printing.enable = true;
    printing.drivers = with pkgs; [ gutenprint brlaser brgenml1lpr brgenml1cupswrapper ];
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
      };
      desktopManager.gnome = {
        enable = true;
        extraGSettingsOverrides = ''
          [org.gnome.desktop.input-sources]
          sources=[('xkb', '${xkbVariant}')]
          xkb-options=['${xkbOptions}']
        '';
      };
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.bara = {
    isNormalUser = true;
    uid = 1000;
    group = "bara";
    extraGroups = [ "dialout" "avahi" "users" "video" "wheel" "adm" "audio" "docker" "input" "vboxusers" "adbusers" "libvirtd" "plugdev" ];
    createHome = true;
    shell = pkgs.fish;
  };
  users.extraGroups.bara.gid = 1000;

  services.udev.packages = with pkgs; [ 
    openhantek6022
  ];

  environment.systemPackages = with pkgs; [
    aspell
    aspellDicts.de
    aspellDicts.en
    avahi
    cifs-utils
    curl
    docker
    dosfstools
    espeak
    emote
    unzip
    evince
    direnv
    delta
    dhall
    dhall-json
    dogdns
    firefox
    file
    gimp
    gitAndTools.gitFull
    git-lfs
    gnumake
    gnome-usage
    google-chrome
    google-cloud-sdk
    gsmartcontrol
    hdparm
    btop
    htop
    imagemagick
    iotop
    lm_sensors
    lutris
    meld
    mellowplayer
    mumble
    mtools
    nmap
    nodejs-14_x
    ntfs3g
    nvme-cli
    octave
    openhantek6022
    pamixer
    pass
    pciutils
    peek
    pavucontrol
    pwgen
    python
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
    super-slicer-latest
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
    x2goclient
    xpra
    (callPackage ../pkgs/vscode.nix {})
    # Broken https://github.com/NixOS/nixpkgs/pull/172335
    #(callPackage ../pkgs/dotnetSdk.nix {})
    (callPackage ../pkgs/lens.nix {})
    (callPackage ../pkgs/vim.nix {})
  ] ++ (with gnomeExtensions; [
    appindicator
    bing-wallpaper-changer
    bluetooth-quick-connect
    system-monitor
    tiling-assistant
  ]) ++ (with fishPlugins; [ done forgit fzf-fish ]);

  services.gvfs.enable = true;
  services.fwupd.enable = true;
  services.gnome = {
    chrome-gnome-shell.enable = true;
    gnome-keyring.enable = true;
    gnome-online-accounts.enable = true;
    gnome-online-miners.enable = true;
    #gnome-user-share.enable = true;
    tracker-miners.enable = true;
    tracker.enable = true;
    sushi.enable = true;
  };
  services.dleyna-renderer.enable = false;

  services.earlyoom.enable = true;

  programs.seahorse.enable = true;
  programs.gnome-terminal.enable = true;
  programs.gnome-disks.enable = true;

  # ram verdoppler
  zramSwap.enable = false;

  programs.adb.enable = true;
  programs.bash.enableCompletion = true;
  programs.zsh.enable = true;
  programs.fish.enable = true;

  # raise limit to avoid steamplay problems
  systemd.extraConfig = "DefaultLimitNOFILE=1048576";

  # directly run the missing commands via nix-shell (without installing anything)
  programs.command-not-found.enable = true;
  environment.variables.NIX_AUTO_RUN = "1";

  hardware.bluetooth = {
    enable = true;
    package = pkgs.bluezFull;
  };

  virtualisation.spiceUSBRedirection.enable = true;

  nyris.programs.enable = true;
}

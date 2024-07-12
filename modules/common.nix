# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:
{
  nix = {
    package = pkgs.nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes ca-derivations
    '';
    settings = {
      trusted-users = [ "root" "@wheel" ];
      substituters = [
        "https://cache.nixos.org/"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];

    };
    gc = {
      options = "--delete-older-than 30d";
    };
  };
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [ ];

  hardware.graphics.enable32Bit = true;

  hardware.ksm.enable = true;

  boot.loader.systemd-boot.memtest86.enable = true;
  boot.extraModprobeConfig = ''
    # exclusive_caps: Skype, Zoom, Teams etc. will only show device when actually streaming
    # card_label: Name of virtual camera, how it'll show up in Skype, Zoom, Teams
    # https://github.com/umlaeute/v4l2loopback
    options v4l2loopback exclusive_caps=1 card_label="Virtual Camera" video_nr=7
  '';

  console = {
    keyMap = "us";
  };

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "de_DE.UTF-8/UTF-8"
  ];

  time.timeZone = "Europe/Berlin";

  #documentation.man.generateCaches = false;

  hardware.sane.enable = true;
  hardware.sane.disabledDefaultBackends = [ "v4l" ];

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

  security.rtkit.enable = true;
  services.smartd.enable = true;

  services.envfs.enable = true;
  services.envfs.extraFallbackPathCommands = ''
  ln -s ${pkgs.bash}/bin/bash $out/bash
  ln -s ${pkgs.coreutils}/bin/uname $out/uname
  '';


  services = {
    flatpak.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true;
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
    displayManager = {
      autoLogin = {
        enable = false;
        user = "bara";
      };
      defaultSession = "gnome";
    };
    xserver =
    let xkbVariant = "altgr-intl"; # no dead keys
        xkbOptions = "eurosign:e,compose:menu,lv3:caps_switch";
    in {
      displayManager.gdm.enable = true;
      enable = true;
      exportConfiguration = true;

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
    extraGroups = [ "dialout" "scanner" "avahi" "users" "video" "wheel" "adm" "audio" "docker" "input" "vboxusers" "adbusers" "libvirtd" "plugdev" ];
    createHome = true;
    shell = pkgs.zsh;
  };
  users.extraGroups.bara.gid = 1000;

  services.udev.packages = with pkgs; [ ];

  environment.systemPackages = with pkgs; [
    _1password-gui
    appimage-run
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
    distrobox
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
    keepass
    lazygit
    hdparm
    hyprpaper
    btop
    htop
    imagemagick
    immersed-vr
    iotop
    lm_sensors
    lsof
    meld
    mellowplayer
    mumble
    mtools
    ncdu
    nixd
    nmap
    nodejs-18_x
    ntfs3g
    nvme-cli
    octave
    pamixer
    pass
    pciutils
    #peek
    pavucontrol
    pdfgrep
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
    skopeo
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
    youtube-music
    (callPackage ../pkgs/vscode.nix {})
    vscode-fhs
    zed-editor
    # Broken https://github.com/NixOS/nixpkgs/pull/172335
    (callPackage ../pkgs/dotnetSdk.nix {})
    (callPackage ../pkgs/vim.nix {})
  ] ++ (with gnomeExtensions; [
    quick-settings-audio-devices-hider
    appindicator
    bing-wallpaper-changer
    bluetooth-quick-connect
    system-monitor-next
    tiling-assistant
    pop-shell
    blur-my-shell
    weeks-start-on-monday-again
    (gesture-improvements.overrideAttrs (a: {
      postInstall = ''
        sed -i 's/"42"/"43"/' $out/share/gnome-shell/extensions/gestureImprovements@gestures/metadata.json
      '';
    }))
  ]);

  hardware.openrazer = {
    enable = false;
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
  #programs.seahorse.enable = true;
  programs.gnome-terminal.enable = true;
  programs.gnome-disks.enable = true;
  programs.gnupg.agent = {
    enable = true;
  };
  services.pcscd.enable = true;

  programs.kdeconnect = {
    package = pkgs.gnomeExtensions.gsconnect;
    enable = true;
  };

  programs.nix-index.enable = true;
  programs.nix-index.enableZshIntegration = true;
  programs.command-not-found.enable = false;
  programs.adb.enable = true;
  programs.bash.completion.enable = true;
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };

  programs.nix-ld.enable = true;

  # raise limit to avoid steamplay problems
  systemd.extraConfig = "DefaultLimitNOFILE=1048576";

  # directly run the missing commands via nix-shell (without installing anything)
  environment.variables.NIX_AUTO_RUN = "1";
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  hardware.bluetooth.enable = true;
  hardware.logitech.wireless.enable = true;
  hardware.logitech.wireless.enableGraphical = true;
  hardware.usb-modeswitch.enable = true;

  virtualisation.spiceUSBRedirection.enable = true;
  programs.ssh.askPassword = pkgs.lib.mkForce "${pkgs.gnome.seahorse.out}/libexec/seahorse/ssh-askpass";

  programs.fuse.userAllowOther = true;
}

# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
let
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
  #wineFull = unstable.pkgs.wineWowPackages.full.override { wineRelease = "staging";};
  #wineFull = unstable.pkgs.wineWowPackages.full;
in
{
  nix.daemonIONiceLevel = 5;
  nix.daemonNiceLevel = 5;

  nixpkgs.config.allowUnfree = true;

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./host.nix
    ];

  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;

  hardware.ksm.enable = true;


  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "us";
    defaultLocale = "en_US.UTF-8";
  };

  time.timeZone = "Europe/Berlin";



  fonts = {
    enableDefaultFonts = true;
    enableFontDir = true;
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
    ];
  };

  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
    package = pkgs.pulseaudioFull;
  };

  services = {
    flatpak.enable = true;
    avahi = {
      enable = true;
      nssmdns = true;
    };
    openssh.enable = true;
    openssh.forwardX11 = true;
    udisks2.enable = true;
    printing.enable = true;
    xserver = 
    let xkbVariant = "altgr-intl"; # no dead keys
        xkbOptions = "eurosign:e,compose:menu,lv3:caps_switch";
    in {
      inherit xkbVariant xkbOptions;

      enable = true;
      layout = "us";
      exportConfiguration = true;

      displayManager.gdm = {
        enable = true;
        wayland = false;
        autoLogin = {
          enable = false;
          user = "bara";
        };
      };
      desktopManager.gnome3 = {
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
    extraGroups = [ "dialout" "avahi" "users" "video" "wheel" "adm" "audio" "docker" "input" "vboxusers" "adbusers" "libvirtd" ];
    createHome = true;
    shell = pkgs.zsh;
  };
  users.extraGroups.bara.gid = 1000;


  environment.systemPackages = with pkgs; [
    aspell
    aspellDicts.de
    aspellDicts.en
    autojump
    avahi
    bc
    cifs-utils
    curl
    darktable
    dmenu
    docker
    dosfstools
    dunst
    emacs
    espeak
    evince
    firefox
    gimp
    gitAndTools.gitFull
    #gnomeExtensions.system-monitor broken
    gnumake
    google-chrome
    google-cloud-sdk
    gpicview
    gtk_engines
    hdparm
    htop
    i3
    i3lock
    i3status
    imagemagick
    iotop
    lightdm
    lightdm_gtk_greeter
    lightlocker
    lm_sensors
    meld
    mtools
    #mumble
    networkmanagerapplet
    ntfs3g
    numlockx
    owncloudclient
    pamixer
    pass
    pavucontrol
    pcmanfm
    python
    renameutils
    rofi
    roxterm
    seafile-client
    slack
    #smartgithg
    source-code-pro
    speechd
    sshfsFuse
    synergy
    teamviewer
    unstable.google-chrome
    unstable.jetbrains.rider
    vlc
    wget
    xorg.xmodmap
    xsettingsd
    xss-lock
    zsh
    #wineFull
    samba

    #springLobby
    #(buildFHSUserEnv {
    #  name = "springlobbyFHS";
    #  targetPkgs = _: [
    #    libGL
    #    curlFull
    #    libGLU
    #    openal
    #    openssl
    #    SDL2 
    #    ((springLobby.overrideAttrs (old: {
    #      postInstall = "wrapProgram $out/bin/springlobby";
    #    })).override { curl = curlFull; })
    #  ];
    #  runScript = "springlobby";
    #  inherit (springLobby) meta;
    #})
    #(winetricks.override { wine = wineFull; })
    (nmap.override {
        graphicalSupport = true;
    })
    (vim_configurable.customize {
      name = "vim";
      vimrcConfig.customRC = ''
      syntax enable
      set smartindent
      set smartcase
      set cursorline
      set visualbell
      set hlsearch
      set incsearch
      set ruler
      set backspace=indent,eol,start
      '';
      vimrcConfig.vam.knownPlugins = pkgs.vimPlugins;
      vimrcConfig.vam.pluginDictionaries = [
        { names = [
          "vim-nix"
        ];}
      ];
    })
    # use version with seccomp fix
    (proot.overrideAttrs (oldAttrs: {
      src = fetchFromGitHub {
        repo = "proot";
        owner = "jorge-lip";
        rev = "25e8461cbe56a3f035df145d9d762b65aa3eedb7";
        sha256 = "1y4rlx0pzdg4xsjzrw0n5m6nwfmiiz87wq9vrm6cy8r89zambs7i";
      };
      version = "5.1.0.20171102";
    }))
  ];

  services.gvfs.enable = true;
  services.gnome3 = {
    chrome-gnome-shell.enable = true;
    gnome-keyring.enable = true;
    gnome-online-accounts.enable = true;
    gnome-online-miners.enable = true;
    gnome-user-share.enable = true;
    tracker-miners.enable = true;
    tracker.enable = true;
    sushi.enable = true;
  };

  programs.seahorse.enable = true;
  programs.gnome-terminal.enable = true;
  programs.gnome-documents.enable = true;
  programs.gnome-disks.enable = true;

  #services.teamviewer.enable = true;
  services.emacs = {
    defaultEditor = true;
    install = true;
  };

  # ram verdoppler
  zramSwap.enable = false;

  programs.adb.enable = true;
  programs.bash.enableCompletion = true;
  programs.zsh.enable = true;

  #environment.etc."qemu/bridge.conf".text = ''
  #  allow bridge0
  #'';
  boot.kernelParams = [
    "spectre_v2=off"
    "nopti"
    "bluetooth.disable_ertm=1"
  ];
  boot.kernelModules = [ "uinput" ];

  # raise limit to avoid steamplay problems
  systemd.extraConfig = "DefaultLimitNOFILE=1048576";

  programs.autojump.enable = true;

  hardware.bluetooth = {
    enable = true;
    package = pkgs.bluezFull;
  };
}

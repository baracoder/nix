# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
let
  baseconfig = { allowUnfree = true; };
  unstable = import <nixos-unstable> { config = baseconfig; };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./host.nix
      ./common-packages.nix
    ];

  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;

  hardware.enableKSM = true;


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
    xserver = {
      enable = true;
      layout = "us";
      xkbVariant = "altgr-intl"; # no dead keys
      xkbOptions = "eurosign:e,compose:menu,lv3:caps_switch";
      exportConfiguration = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome3.enable = true;
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.bara = {
    isNormalUser = true;
    uid = 1000;
    group = "bara";
    extraGroups = [ "dialout" "avahi" "users" "video" "wheel" "adm" "audio" "docker" "input" "vboxusers" "adbusers" "libvirtd" ];
    createHome = true;
    shell = "/run/current-system/sw/bin/zsh";
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
    gcc
    gimp
    gitAndTools.gitFull
    gnomeExtensions.system-monitor
    gnumake
    google-chrome
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
    master.pkgs.steam
    meld
    mtools
    mumble
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
    smartgithg
    source-code-pro
    speechd
    sshfsFuse
    steamcontroller-udev-rules
    synergy
    teamviewer
    unstable.google-chrome
    unstable.jetbrains.rider
    unstable.pkgs.steam
    unstable.sway
    vlc
    wget
    wine
    xorg.xmodmap
    xpra
    xsettingsd
    xss-lock
    zsh
    
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

  # steam controller udev rule
  nixpkgs.config.packageOverrides = super: let self = super.pkgs; in {

    teamviewer = unstable.teamviewer;
    steamcontroller-udev-rules = pkgs.writeTextFile {
      name = "steamcontroller-udev-rules";
      text = ''
# This rule is needed for basic functionality of the controller in Steam and keyboard/mouse emulation
SUBSYSTEM=="usb", ATTRS{idVendor}=="28de", MODE="0666"
#
# # This rule is necessary for gamepad emulation; make sure you replace 'users' with a group that the user that runs Steam belongs to
KERNEL=="uinput", MODE="0660", GROUP="users", OPTIONS+="static_node=uinput"
#
# # Valve HID devices over USB hidraw
KERNEL=="hidraw*", ATTRS{idVendor}=="28de", MODE="0666"
#
# # Valve HID devices over bluetooth hidraw
KERNEL=="hidraw*", KERNELS=="*28DE:*", MODE="0666"

      '';
      destination = "/etc/udev/rules.d/99-steamcontroller.rules";
    };
  };

  services.gnome3 = {
    chrome-gnome-shell.enable = true;
    gnome-documents.enable = true;
    gnome-disks.enable = true;
    gnome-keyring.enable = true;
    gnome-online-accounts.enable = true;
    gnome-online-miners.enable = true;
    gnome-terminal-server.enable = true;
    gnome-user-share.enable = true;
    tracker-miners.enable = true;
    tracker.enable = true;
    gvfs.enable = true;
    seahorse.enable = true;
    sushi.enable = true;
  };

  services.udev.packages = [ pkgs.steamcontroller-udev-rules ];
  services.teamviewer.enable = true;
  services.emacs = {
    defaultEditor = true;
    install = true;
  };

  # ram verdoppler
  zramSwap.enable = false;

  programs.adb.enable = true;
  programs.bash.enableCompletion = true;

  #environment.etc."qemu/bridge.conf".text = ''
  #  allow bridge0
  #'';
  boot.kernelParams = [
    "spectre_v2=off"
    "nopti"
    "bluetooth.disable_ertm=1"
  ];

  # raise limit to avoid steamplay problems
  systemd.extraConfig = "DefaultLimitNOFILE=1048576";
}

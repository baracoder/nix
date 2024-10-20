{pkgs, config, lib, ...}:

{
  hardware.graphics.enable32Bit = true;

  hardware.ksm.enable = true;

  console = {
    keyMap = "us";
  };

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "de_DE.UTF-8/UTF-8"
  ];


  hardware.sane.enable = true;
  hardware.sane.disabledDefaultBackends = [ "v4l" ];

  boot.kernel.sysctl."kernel.dmesg_restrict" = 0;
  boot.loader.systemd-boot.memtest86.enable = true;
  boot.extraModprobeConfig = ''
    # exclusive_caps: Skype, Zoom, Teams etc. will only show device when actually streaming
    # card_label: Name of virtual camera, how it'll show up in Skype, Zoom, Teams
    # https://github.com/umlaeute/v4l2loopback
    options v4l2loopback exclusive_caps=1 card_label="Virtual Camera" video_nr=7
  '';


  time.timeZone = "Europe/Berlin";


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
  services.pipewire = {
    enable = true;
    wireplumber.enable = true;
    pulse.enable = true;
    jack.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
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

  services.gvfs.enable = true;
  services.fwupd.enable = true;
  services.gnome = {
    gnome-browser-connector.enable = true;
    gnome-keyring.enable = true;
    gnome-online-accounts.enable = true;
    #gnome-user-share.enable = true;
    tracker-miners.enable = true;
    tracker.enable = true;
    sushi.enable = true;
    at-spi2-core.enable = true;
  };

  services.earlyoom.enable = true;

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


  services.envfs.enable = true;
  services.envfs.extraFallbackPathCommands = ''
  ln -s ${pkgs.bash}/bin/bash $out/bash
  ln -s ${pkgs.coreutils}/bin/uname $out/uname
  '';

  security.rtkit.enable = true;
  services.smartd.enable = true;

  xdg.autostart.enable = true;
  xdg.portal = {
    xdgOpenUsePortal = true;
    enable = true;
  };

  programs.immersed.enable = true;
  programs.firefox = {
    enable = true;
    languagePacks = [ "en-US" "de" ];
  };
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
  programs.adb.enable = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    icu
    icu75
  ];

  # raise limit to avoid steamplay problems
  systemd.extraConfig = "DefaultLimitNOFILE=1048576";

  programs.fuse.userAllowOther = true;

  virtualisation.spiceUSBRedirection.enable = true;

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  hardware.bluetooth.enable = true;
  hardware.logitech.wireless.enable = true;
  hardware.logitech.wireless.enableGraphical = true;
  hardware.usb-modeswitch.enable = true;


  programs.nix-index.enable = true;
  programs.nix-index.enableZshIntegration = true;
  programs.command-not-found.enable = false;
  programs.bash.completion.enable = true;
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };

  environment.systemPackages = with pkgs; [
    aspell
    aspellDicts.de
    aspellDicts.en
    appimage-run
    ausweisapp
    avahi
    cifs-utils
    espeak
    evince
    gitg
    gnome-console
    gnome-usage
    google-chrome
    gnome-tweaks
    gsmartcontrol
    hdparm
    lm_sensors
    iotop
    keepass
    mtools
    mumble
    ntfs3g
    nvme-cli
    pamixer
    pciutils
    pavucontrol
    qjackctl
    remmina
    gnome-boxes
    ghex
    spice-gtk
    speechd
    sshfs-fuse
    usbutils
    virt-manager
    vlc
    wireguard-tools
    xpra
    zed-editor

    (callPackage ../pkgs/vscode.nix {})
    vscode-fhs
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
}
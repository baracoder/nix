{
  pkgs,
  ...
}:

{
  networking.extraHosts = ''
    192.168.98.3 wau
  '';

  hardware.graphics.enable32Bit = true;
  hardware.graphics.enable = true;

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
      #nerd-fonts.source-code-pro
      nerd-fonts.fira-code
      nerd-fonts.droid-sans-mono
      nerd-fonts.dejavu-sans-mono
      #nerd-fonts.terminus
    ];
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
    extraGroups = [
      "dialout"
      "scanner"
      "users"
      "video"
      "wheel"
      "adm"
      "audio"
      "docker"
      "input"
      "vboxusers"
      "adbusers"
      "libvirtd"
      "plugdev"
      "networkmanager"
    ];
    createHome = true;
    shell = pkgs.zsh;
  };
  users.extraGroups.bara.gid = 1000;

  services.gvfs.enable = true;
  services.fwupd.enable = true;

  services.earlyoom.enable = true;

  services = {
    flatpak.enable = true;
    resolved = {
      enable = false;
      fallbackDns = [ "" ];
    };
    openssh.enable = true;
    openssh.settings.X11Forwarding = true;
    udisks2.enable = true;
    printing.enable = true;
    printing.drivers = with pkgs; [
      gutenprint
      brlaser
      brgenml1lpr
      brgenml1cupswrapper
      hplip
    ];
    displayManager = {
      autoLogin = {
        enable = false;
        user = "bara";
      };
      defaultSession = "gnome";
    };
    displayManager.gdm.enable = true;
    xserver.enable = true;

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
    languagePacks = [
      "en-US"
      "de"
    ];
  };
  programs.gnupg.agent = {
    enable = true;
  };
  services.pcscd.enable = true;

  programs.adb.enable = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    icu
    icu75
    xorg.libX11
    xorg.libXext
    libgbm
    libusb1
  ];

  # raise limit to avoid steamplay problems
  systemd.settings.Manager.DefaultLimitNOFILE = 1048576;
  programs.fuse.userAllowOther = true;

  virtualisation.spiceUSBRedirection.enable = true;

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  hardware.bluetooth.enable = true;

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

  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;

  environment.systemPackages = with pkgs; [
    aspell
    aspellDicts.de
    aspellDicts.en
    #appimage-run
    ausweisapp
    avahi
    blackbox-terminal
    cifs-utils
    espeak
    evince
    dconf-editor
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
    ghostty
    gnome-boxes
    ghex
    ptyxis
    spice-gtk
    speechd
    sshfs-fuse
    usbutils
    virt-manager
    vlc
    wireguard-tools
    wl-clipboard
    xpra
    alsa-utils
    show-midi

    (callPackage ../pkgs/vscode.nix { })
    vscode-fhs
  ];
}

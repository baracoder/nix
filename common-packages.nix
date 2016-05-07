{ config, pkgs, ... }:

{

  nixpkgs.config.allowUnfree = true;



  environment.systemPackages = with pkgs; [
    espeak
    avahi
    bcache-tools
    chromium
    curl
    dmenu
    docker
    darktable
    evince
    firefox
    gcc
    gitAndTools.gitFull
    gnumake
    hdparm
    htop
    lm_sensors
    i3
    i3lock
    i3status
    iotop
    lightdm
    lightdm_gtk_greeter
    (speechd.override {
        withEspeak = true;
    })
    (mumble.override {
        pulseSupport = true;
        speechdSupport = true;
    })
    neovim
    networkmanagerapplet
    numlockx
    pamixer
    pavucontrol
    pcmanfm
    python
    roxterm
    slack
    spotify
    sshfsFuse
    synergy
    vim
    wget
    wine
    xorg.xmodmap
    xss-lock
    zsh
  ];

}

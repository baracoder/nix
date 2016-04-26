{ config, pkgs, ... }:

{

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    avahi
    bcache-tools
    chromium
    curl
    dmenu
    docker
    evince
    firefox
    gcc
    gitAndTools.gitFull
    gnumake
    i3
    i3lock
    i3status
    lightdm
    lightdm_gtk_greeter
    mumble
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

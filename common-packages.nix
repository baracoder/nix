{ config, pkgs, ... }:

{

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    bcache-tools
    chromium
    curl
    dmenu
    docker
    gitAndTools.gitFull
    gnumake
    i3
    i3lock
    i3status
    lightdm
    mumble
    neovim
    numlockx
    pamixer
    pavucontrol
    pcmanfm
    roxterm
    slack
    spotify
    springLobby
    sshfsFuse
    steam
    synergy
    vim
    wget
    wine
    xorg.xmodmap
    xss-lock
    zsh
  ];

}

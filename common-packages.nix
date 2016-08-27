{ config, pkgs, ... }:

let
  unstable = (import (fetchTarball https://nixos.org/releases/nixos/unstable/nixos-16.09pre83100.25e3c09/nixexprs.tar.xz) {}).pkgs;

in {

  nixpkgs.config.allowUnfree = true;



  environment.systemPackages = with pkgs; [
    google-chrome
    polkit_gnome
    dunst
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
    (unstable.nmap.override {
        graphicalSupport = true;
    })
    (unstable.speechd.override {
        withEspeak = true;
    })
    (unstable.mumble.override {
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
    unstable.spotify
    sshfsFuse
    synergy
    vim
    wget
    wine
    xorg.xmodmap
    xss-lock
    zsh
  ] ++ builtins.filter stdenv.lib.isDerivation (builtins.attrValues gnome3);

}

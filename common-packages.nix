{ config, pkgs, ... }:

let
  unstable = (import (fetchTarball https://nixos.org/channels/nixos-unstable/nixexprs.tar.xz?123) {
  config.allowUnfree = true;
}).pkgs;
in
 {

  nixpkgs.config = {
    allowUnfree = true;
    chromium = {
     enablePepperPDF = true;
    };
  };

  environment.systemPackages = with pkgs; [
    unstable.sway
    xsettingsd
    lightlocker
    source-code-pro
    owncloudclient
    pass
    rofi
    emacs
    google-chrome
    gimp
    imagemagick
    autojump
    renameutils
    bc
    seafile-client
    meld
    vlc
    mtools
    dosfstools
    ntfs3g
    dunst
    espeak
    avahi
    chromium
    curl
    dmenu
    docker
    darktable
    evince
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
    springLobby
    (nmap.override {
        graphicalSupport = true;
    })
    speechd
    mumble
    aspell
    aspellDicts.de
    aspellDicts.en
    gpicview
    networkmanagerapplet
    numlockx
    pamixer
    pavucontrol
    pcmanfm
    python
    roxterm
    slack
    sshfsFuse
    steam
    synergy
    vim
    wget
    wine
    xorg.xmodmap
    xss-lock
    zsh
    gtk_engines
    texlive.combined.scheme-full
  ] ;

}

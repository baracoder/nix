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
     enablePepperFlash = true; # Chromium's non-NSAPI alternative to Adobe Flash
     enablePepperPDF = true;
    };
  };




  environment.systemPackages = with pkgs; [
    owncloudclient
    pass
    rofi
    unstable.google-musicmanager
    emacs
    google-chrome
    unstable.vscode
    gimp
    imagemagick
    oraclejre8
    autojump
    renameutils
    bc
    seafile-client
    meld
    vlc
    remmina
    mtools
    dosfstools
    ntfs3g
    unstable.remmina
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
    springLobby
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
    gpicview
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
    steam
    synergy
    vim
    wget
    wine
    xorg.xmodmap
    xss-lock
    zsh
    gtk_engines
  ] ++ builtins.filter stdenv.lib.isDerivation (builtins.attrValues gnome3);

}

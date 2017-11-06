{ config, pkgs, ... }:

let
  unstable = (import (fetchTarball https://nixos.org/channels/nixos-unstable/nixexprs.tar.xz) {
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
    firefox-esr
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
    gtk_engines
    xpra
  ];

}

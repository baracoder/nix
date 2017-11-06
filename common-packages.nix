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
     enablePepperFlash = true; # Chromium's non-NSAPI alternative to Adobe Flash
     enablePepperPDF = true;
    };
  };

  environment.systemPackages = with pkgs; [
    xsettingsd
    lightlocker
    gnome3.gnome_session
    source-code-pro
    owncloudclient
    pass
    rofi
    unstable.google-musicmanager
    emacs
    google-chrome
    unstable.vscode
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
    unstable.speechd
    mumble
    aspell
    aspellDicts.de
    aspellDicts.en
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
    sshfsFuse
    unstable.steam
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

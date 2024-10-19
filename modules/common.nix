{ config, pkgs, inputs, ... }:
{

  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [ "root" "@wheel" ];
      substituters = [
        "https://cache.nixos.org/"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];

    };
    gc = {
      options = "--delete-older-than 30d";
    };
  };
  nixpkgs.config.allowUnfree = true;


  #documentation.man.generateCaches = false;


  environment.systemPackages = with pkgs; [
    curl
    docker
    docker-compose
    dosfstools
    unzip
    direnv
    dogdns
    file
    gimp
    gitAndTools.gitFull
    gitflow
    git-lfs
    glab
    gnumake
    k9s
    kubectl
    lazygit
    btop
    htop
    imagemagick
    immersed-vr
    lsof
    meld
    ncdu
    nixd
    nmap
    nodejs-18_x
    nvd
    octave
    pass
    #peek
    pdfgrep
    pre-commit
    pwgen
    python3
    renameutils
    ripgrep
    skopeo
    sqlite
    wget
    fzf
    fd
    tldr
    zsh
    samba
    wireshark
    nix-tree
    vulnix
    yaml-language-server
    # Broken https://github.com/NixOS/nixpkgs/pull/172335
    (callPackage ../pkgs/dotnetSdk.nix {})
    (callPackage ../pkgs/vim.nix {})
  ];



  # directly run the missing commands via nix-shell (without installing anything)
  environment.variables.NIX_AUTO_RUN = "1";


}

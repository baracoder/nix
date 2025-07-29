{
  config,
  pkgs,
  inputs,
  ...
}:
{

  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [
        "root"
        "@wheel"
      ];
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
    codebook
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
    git-lfs
    gnumake
    grpcurl
    k9s
    kubectl
    lazygit
    lnav
    lsp-ai
    btop
    helix
    htop
    imagemagick
    immersed
    lsof
    jetbrains.rider
    meld
    ncdu
    nixd
    nixfmt
    netcoredbg
    nmap
    nvd
    octave
    omnisharp-roslyn
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
    yaml-language-server
    (callPackage ../pkgs/vim.nix { })
    (dotnetCorePackages.combinePackages (
      with dotnetCorePackages;
      [
        sdk_9_0
        sdk_8_0
      ]
    ))
    jq
    yq-go
    kube-score
  ];

  # directly run the missing commands via nix-shell (without installing anything)
  environment.variables.NIX_AUTO_RUN = "1";

}

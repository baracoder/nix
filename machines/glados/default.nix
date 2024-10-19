{ pkgs, ... }:

{
  nixpkgs.hostPlatform = "aarch64-darwin";
  environment.systemPackages = with pkgs; [
    kubectl
    meld
    _1password
    gh
    gitFull
    awscli2
    direnv
    fzf
    htop
    jq
    colima
    eksctl
    k9s
    go_1_22
    kubernetes-helm
    kustomize
  ];

  system.stateVersion = 5;

  programs.zsh.enable = true;

  services.nix-daemon.enable = true;
  #nix.package = pkgs.nix;
  nixpkgs.config.allowUnfree = true;

}
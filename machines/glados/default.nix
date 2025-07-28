{ pkgs, ... }:

{
  nixpkgs.hostPlatform = "aarch64-darwin";

  nix.linux-builder.enable = true;

  environment.systemPackages = with pkgs; [
    kubectl
    meld
    _1password-cli
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
    kubernetes-helm
    kustomize
    tfswitch
    remmina
    wireshark
    kaf
    kcat
    valkey
    yarn
    jujutsu
    lazyjj
  ];

  system.stateVersion = 5;

  programs.zsh.enable = true;

  #nix.package = pkgs.nix;
  nixpkgs.config.allowUnfree = true;

}

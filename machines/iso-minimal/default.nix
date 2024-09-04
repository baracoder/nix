{ lib, pkgs, ... }: {
  boot.supportedFilesystems = [ "bcachefs" ];
  boot.kernelPackages = lib.mkOverride 0 pkgs.linuxPackages_latest;
  nix = {
    package = pkgs.nixVersions.latest;
      extraOptions = ''
        experimental-features = nix-command flakes ca-derivations
      '';
  };
  environment.systemPackages = with pkgs; [
    git
  ];
}
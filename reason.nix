{ config, pkgs, ... }:

{
  boot.loader.gummiboot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "reason";
  environment.systemPackages = with pkgs; [
  ];
  virtualisation.docker.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  system.stateVersion = "16.03";
  powerManagement.powerUpCommands="/var/run/current-system/sw/sbin/hdparm -S 120 /dev/sd[a-z]";
}

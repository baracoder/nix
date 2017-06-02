{ config, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "reason";

  environment.systemPackages = with pkgs; [
  ];
  virtualisation.docker = {
    enable = true;
    storageDriver = "overlay";
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  system.stateVersion = "16.03";
  powerManagement.powerUpCommands="/var/run/current-system/sw/sbin/hdparm -S 120 /dev/sd[a-z]";


  # samba for windows share
  services.samba = {
    enable = true;
    securityType = "user";
    shares = {
      homeBara = {
        "read only" = false;
        browseable = "yes";
        comment = "home directory";
        "guest ok" = "no";
        path = "/home/bara";
      };
    };
  };
}

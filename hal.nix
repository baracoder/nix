{ config, pkgs, ... }:

{

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";
  boot.initrd.extraKernelModules = [ "bcache" ];
  boot.initrd.luks.devices = [
    { name = "storage"; device = "/dev/bcache0"; }
  ];

  environment.systemPackages = with pkgs; [
    springLobby
    steam
  ];

  networking.hostName = "hal";
  networking.firewall.enable = false;

  services.xserver.videoDrivers = [ "nvidia" ];
  system.stateVersion = "16.03";

}

{ config, pkgs, ... }:

{
  boot.loader.gummiboot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices = [
    { name = "nixos-root"; device = "/dev/sda4";  allowDiscards = true; }
    { name = "gentoo-root"; device = "/dev/sda2";  allowDiscards = true; }
  ];
  hardware.trackpoint.emulateWheel = true;
  networking.hostName = "hex"; # Define your hostname.
  networking.networkmanager.enable = true;
  environment.systemPackages = with pkgs; [
    xorg.xbacklight
    qtcreator
    steam
  ];
  virtualisation.docker.enable = true;
  system.stateVersion = "16.03";
}

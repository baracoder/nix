{ config, pkgs, ... }:

{
  boot.loader.gummiboot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices = [
    { name = "nixos-root"; device = "/dev/sda2";  allowDiscards = true; }
  ];
  hardware.trackpoint.emulateWheel = true;
  networking.hostName = "hex";
  networking.networkmanager.enable = true;
  environment.systemPackages = with pkgs; [
    xorg.xbacklight
    qtcreator
    steam
  ];
  # power management
  services.tlp.enable = true;

  virtualisation.docker.enable = true;
  virtualisation.virtualbox.host.enable = true;
  system.stateVersion = "16.03";
}

{ config, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    firewall.enable = false;
    hostName = "reason";
    networkmanager.enable = false;
    bridges.bridge0 = {
      interfaces = [ "enp6s0" ];
    };
    defaultGateway = {
      address = "192.168.0.1";
      interface = "bridge0";
    };
    dhcpcd.enable = false;
    nameservers = [
      "192.168.0.1"
    ];
    search = [ "fritz.box" ];
    interfaces.bridge0.ip4 = [{
      address = "192.168.0.32";
      prefixLength = 24;
    }] ;
  };


  environment.systemPackages = with pkgs; [
  ];
  virtualisation.docker = {
    enable = true;
    storageDriver = "overlay";
    extraOptions = "-H tcp://192.168.0.32:2375";
  };
  virtualisation.libvirtd.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  system.stateVersion = "17.03";
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

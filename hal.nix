{ config, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.timeout = null;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.extraModprobeConfig = ''
    options bluetooth disable_ertm=1
  '';


  hardware.bluetooth.enable = true;
  hardware.steam-hardware.enable = true;

  boot.initrd.luks.devices."crypt-ssd".allowDiscards = true;
  fileSystems."/".options= ["defaults" "discard" ];

  swapDevices = [
    {
      device = "/dev/disk/by-partlabel/cryptswap";
      randomEncryption.enable = true;
    }
  ];
  systemd.units."dev-sdc2.swap".enable = false;
  systemd.generators.systemd-gpt-auto-generator = "/dev/null";

  powerManagement = {
    enable = true;
    powerUpCommands = "for i in /dev/sd*; do ${pkgs.hdparm}/sbin/hdparm -S 12 $i; done";
    resumeCommands = "for i in /dev/sd*; do ${pkgs.hdparm}/sbin/hdparm -S 12 $i; done";
  };


  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
    storageDriver = "overlay2";
  };

  services.printing = {
    enable = true;
    drivers = [ pkgs.hplip ];
  };

  services.logind.extraConfig = ''
  HandlePowerKey=suspend
  '';

  networking.hostName = "hal";
  networking.firewall.enable = false;

  services.xserver.videoDrivers = [ "nvidiaBeta" ];
  system.stateVersion = "18.09";

  services.wakeonlan.interfaces = [
    { interface = "enp4s0"; method = "magicpacket"; }
  ];

}

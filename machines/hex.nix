{ config, lib, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.timeout = 0;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.plymouth.enable = true;

  boot.kernelParams = [
    "nopti"
    "mem_sleep_default=deep"
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.fwupd.enable = true;
  services.x2goserver.enable = true;
  services.logind.lidSwitchExternalPower = "ignore";

  networking.hostName = "hex";
  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [ 3389 ];
  environment.systemPackages = with pkgs; [
    xorg.xbacklight
  ];
  # power management
  services.thermald.enable = true;
  services.tlp.enable = false;
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "powersave";
  };

  hardware.opengl.enable = true;
  

  virtualisation.docker.enable = true;
  #virtualisation.virtualbox.host.enable = true;
  system.stateVersion = "18.03";

  boot.initrd.availableKernelModules = [ "wireguard" "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.kernel.sysctl = {
    "vm.swappiness" = lib.mkDefault 1;
  };

  services.globalprotect.enable = true;

  services.fstrim.enable = lib.mkDefault true;
  fileSystems."/" =
    { device = "/dev/disk/by-uuid/782c0b96-19a1-4073-8e35-a20b387da9be";
      fsType = "btrfs";
      options = [ "discard" "noatime" ];
    };

  boot.initrd.luks.devices."nixos-root".device = "/dev/disk/by-uuid/f9ec90cb-4f20-448d-b33b-ffa09c58a4ab";

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/8659-B61F";
      fsType = "vfat";
      options = [ "noatime" ];
    };

  swapDevices = [ ];

  nix.settings.max-jobs = lib.mkDefault 8;
}

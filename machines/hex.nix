{ config, lib, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.timeout = 0;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.plymouth.enable = true;

  boot.kernelParams = lib.mkForce [
    "nopti"
    "mem_sleep_default=s2idle"
    "nvme.noacpi=1"
    "splash"
    "loglevel=4"
  ];

  system.autoUpgrade = {
    enable = true;
    flake = "/home/bara/src/baracoder-nix";
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.fwupd.enable = true;
  services.logind.lidSwitchExternalPower = "ignore";
  services.tlp = {
    enable = true;
    settings = {
      PCIE_ASPM_ON_BAT = "powersupersave";
    };
  };
  services.fprintd.enable = false;

  networking.hostName = "hex";
  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [ 3389 ];
  environment.systemPackages = with pkgs; [
    xorg.xbacklight
    jetbrains.datagrip
    jetbrains.rider
    bespokesynth
    sonic-pi
    clamav
  ];
  services.power-profiles-daemon.enable = false;
  programs.nix-ld.enable = true;

  hardware.opengl = {
      enable = true;
      extraPackages = with pkgs; [ vaapiIntel libvdpau-va-gl ];
      extraPackages32 = with pkgs; [ vaapiIntel libvdpau-va-gl ];
    };

  virtualisation.docker.enable = true;
  virtualisation.docker.extraOptions = "--bip 172.30.0.1/16 --default-address-pool=base=172.30.0.0/16,size=24 --default-address-pool=base=172.40.1.0/16,size=24";
  #virtualisation.virtualbox.host.enable = true;
  system.stateVersion = "18.03";

  boot.initrd.availableKernelModules = [ "wireguard" "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.systemd.enable = true;
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

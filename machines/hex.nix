{ config, lib, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.timeout = 0;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
  boot.initrd.availableKernelModules = [ "wireguard" "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.systemd.enable = true;
  boot.kernel.sysctl = {
    "vm.swappiness" = lib.mkDefault 1;
  };

  #boot.kernelParams = lib.mkForce [
  #  "nopti"
  #  "mem_sleep_default=deep"
  #  "nvme.noacpi=1"
  #  "splash"
  #  "loglevel=4"
  #];
  boot.kernelParams = [ "nopti" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Required for ISO-27001
  system.autoUpgrade = {
    enable = true;
    flake = "/home/bara/src/baracoder-nix";
  };


  services.fwupd.enableTestRemote = true;
  services.logind.lidSwitchExternalPower = "ignore";
  #services.tlp = {
  #  enable = true;
  #  settings = {
  #    PCIE_ASPM_ON_BAT = "powersupersave";
  #  };
  #};
  services.fprintd.enable = false;
  services.power-profiles-daemon.enable = true;
  services.globalprotect.enable = true;

  networking.hostName = "hex";
  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [
    3389
    21000 21013 # immersed-vr
  ];

  environment.systemPackages = with pkgs; [
    libva-utils
    xorg.xbacklight
    (callPackage ../pkgs/drata-agent.nix {})
    clamav
    brightnessctl
  ];

  # required for ISO-27001
  services.clamav.daemon.enable = true;
  services.clamav.updater.enable = true;

  programs.nix-ld.enable = true;

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      vaapiIntel         # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  virtualisation.docker = {
    enable = true;
    extraOptions = "--bip 172.30.0.1/16 --default-address-pool=base=172.30.0.0/16,size=24 --default-address-pool=base=172.40.1.0/16,size=24";
  };
  system.stateVersion = "18.03";


  # fs stuff
  services.fstrim.enable = lib.mkDefault true;
  boot.initrd.luks.devices."nixos-root".device = "/dev/disk/by-uuid/f9ec90cb-4f20-448d-b33b-ffa09c58a4ab";
  boot.initrd.luks.devices."cryptswap".device = "/dev/disk/by-uuid/7edba97a-1db8-4fbd-a0e4-192f42dd779a";

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/782c0b96-19a1-4073-8e35-a20b387da9be";
      fsType = "btrfs";
      options = [ "discard" "noatime" ];
    };
  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/8659-B61F";
      fsType = "vfat";
      options = [ "noatime" ];
    };
  swapDevices = [ { device = "/dev/mapper/cryptswap"; } ];

  nix.settings.max-jobs = lib.mkDefault 8;
}

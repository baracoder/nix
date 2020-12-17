{ config, pkgs, lib, ... }:
let linuxPackages = pkgs.linuxPackages_5_9;
in
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.timeout = null;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = linuxPackages;
  boot.extraModulePackages = with linuxPackages; [ asus-wmi-sensors v4l2loopback ];
  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usbhid" "sd_mod"  "nvme" "nvme_core" ];
  boot.kernelModules = [ "kvm-intel" "nvidia_uvm" "nvidia_drm" "nvidia_modeset" "nvidia" "asus-wmi-sensors" "v4l2loopback" ];

  boot.extraModprobeConfig = ''
    options bluetooth disable_ertm=1
    options v4l2loopback exclusive_caps=1 video_nr=9 card_label="obs"
  '';


  hardware.bluetooth.enable = true;
  hardware.steam-hardware.enable = true;

  boot.initrd.luks.devices."crypt-ssd".allowDiscards = true;

  swapDevices = [
    {
      device = "/dev/disk/by-partlabel/cryptswap";
      randomEncryption.enable = true;
    }
  ];
  systemd.units."dev-sdc2.swap".enable = false;
  systemd.generators.systemd-gpt-auto-generator = "/dev/null";

  powerManagement.enable = true;
  powerManagement.cpuFreqGovernor = "ondemand";


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

  services.xserver.videoDrivers = [ "nvidia" ];
  services.xserver.screenSection = ''
    Option         "metamodes" "DP-2: nvidia-auto-select +0+0 {AllowGSYNCCompatible=On}, HDMI-0: nvidia-auto-select +3440+0"
  '';
  system.stateVersion = "19.09";

  services.wakeonlan.interfaces = [
    { interface = "enp4s0"; method = "magicpacket"; }
  ];

  boot.kernelParams = [
    "bluetooth.disable_ertm=1"
    "nouveau.modeset=0"
  ];

  services.logmein-hamachi.enable = false;
  hardware.nvidia.modesetting.enable = false;


  fileSystems."/" =
    { device = "/dev/disk/by-uuid/606839e6-36e4-41e4-8762-a8ccbe1704ce";
      fsType = "ext4";
      options = [ "discard" "noatime" ];
    };

  boot.initrd.luks.devices."crypt-ssd".device = "/dev/disk/by-uuid/4cee7fa9-8038-4da9-a176-624cdc89a515";

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/CDB5-AD45";
      fsType = "vfat";
      options = [ "noatime" ];
    };



  nix.maxJobs = lib.mkDefault 8;

  hardware.openrazer.enable = true;

}

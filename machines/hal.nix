{ config, pkgs, lib, ... }:
let linuxPackages = pkgs.linuxPackages_5_12;
in
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.timeout = null;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = linuxPackages;
  boot.extraModulePackages = with linuxPackages; [ asus-wmi-sensors v4l2loopback ];
  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usbhid" "sd_mod"  "nvme" "nvme_core" ];
  boot.kernelModules = [ "kvm-intel" "nvidia_uvm" "nvidia_drm" "nvidia_modeset" "nvidia" "asus-wmi-sensors" "v4l2loopback" ];


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
    enableNvidia = true;
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
  services.xserver.deviceSection = ''
    Option "Coolbits" "28"
  '';
  services.xserver.screenSection = ''
    Option         "metamodes" "DP-2: nvidia-auto-select +0+0 {AllowGSYNCCompatible=On}, HDMI-0: nvidia-auto-select +3440+0"
  '';
  system.stateVersion = "19.09";

  services.wakeonlan.interfaces = [
    { interface = "enp4s0"; method = "magicpacket"; }
  ];

  boot.kernelParams = [
    "nouveau.modeset=0"
    # workaround for nvidia docker
    "systemd.unified_cgroup_hierarchy=false" 
    # workaround for https://github.com/ValveSoftware/Proton/issues/2927
    "clearcpuid=514"
  ];

  hardware.nvidia.modesetting.enable = true;
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.beta;
  services.xserver.displayManager.gdm.nvidiaWayland = true;
  programs.xwayland.enable = true;


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


  # blinkblink rgb

  hardware.openrazer.enable = true;
  environment.systemPackages = with pkgs; [ openrgb protontricks ];
  services.udev.packages = with pkgs; [ 
    openrgb
    ( pkgs.writeTextFile {
      name = "extra-udev-rules";
      text = ''
SUBSYSTEM=="input", ATTRS{name}=="relabsd:*", ENV{ID_INPUT_MOUSE}="0", ENV{ID_INPUT_JOYSTICK}="1", ENV{ID_CLASS}="joystick", MODE="0666"
      
      '';
      destination = "/etc/udev/rules.d/99-relabsd.rules";
    } )
  ];
  services.udev.extraRules = ''
    # x52 joystick
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="06a3", ATTRS{idProduct}=="0762", MODE="0666"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="06a3", ATTRS{idProduct}=="0255", MODE="0666"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="06a3", ATTRS{idProduct}=="075c", MODE="0666"

  '';

  programs.steam.enable = true;

}

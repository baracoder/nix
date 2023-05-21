{ config, pkgs, lib, ... }:
let linuxPackages = pkgs.linuxPackages_zen;
    nvidiaPackage = linuxPackages.nvidiaPackages.stable;
in
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.timeout = null;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = linuxPackages;
  boot.extraModulePackages = with linuxPackages; [ asus-wmi-sensors v4l2loopback ];
  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usbhid" "sd_mod"  "nvme" "nvme_core" ];
  boot.kernelModules = [ "kvm-intel" "nvidia_uvm" "nvidia_drm" "nvidia_modeset" "nvidia" "asus-wmi-sensors" "v4l2loopback" "btrfs" ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/65de6b98-348e-454f-a57a-d100cf19bd28";
      fsType = "btrfs";
      options = [ "discard=async" "relatime" "subvol=root" "compress=lzo" ];
    };
  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/65de6b98-348e-454f-a57a-d100cf19bd28";
      fsType = "btrfs";
      options = [ "discard=async" "relatime" "subvol=home" "compress=lzo" ];
    };

  boot.initrd.luks.devices."crypt-ssd".device = "/dev/disk/by-uuid/c822c962-094c-45bc-bb24-ea57062f02a4";
  boot.initrd.luks.devices."crypt-ssd".allowDiscards = true;
  boot.initrd.systemd.enable = true;
  boot.plymouth.enable = true;


  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/4B1E-8899";
      fsType = "vfat";
      options = [ "relatime" ];
    };
  swapDevices = [
    {
      device = "/dev/disk/by-partlabel/crypt-swap";
      randomEncryption.enable = true;
    }
  ];
  systemd.units."dev-sdc2.swap".enable = false;
  systemd.generators.systemd-gpt-auto-generator = "/dev/null";


  hardware.cpu.amd.updateMicrocode = true;
  hardware.bluetooth.enable = true;
  hardware.steam-hardware.enable = true;

  powerManagement.enable = true;
  powerManagement.cpuFreqGovernor = "ondemand";

  virtualisation.waydroid.enable = true;
  virtualisation.libvirtd.enable = true;
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
  networking.interfaces.enp4s0.wakeOnLan.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];
  services.xserver.screenSection = ''
    Option         "metamodes" "DP-2: nvidia-auto-select +0+0 {AllowGSYNCCompatible=On}, HDMI-0: nvidia-auto-select +3440+0"
  '';
  system.stateVersion = "19.09";

  environment.sessionVariables.NIXOS_OZONE_WL = "1";


  boot.kernelParams = [
    "nouveau.modeset=0"
    # workaround for nvidia docker
    "systemd.unified_cgroup_hierarchy=false" 
    # workaround for https://github.com/ValveSoftware/Proton/issues/2927
    "clearcpuid=514"
  ];

  hardware.nvidia = {
    modesetting.enable = true;
    package = nvidiaPackage;
    powerManagement.enable = true;
  };
  programs.xwayland.enable = true;

  nix.settings.max-jobs = lib.mkDefault 8;


  hardware.opengl = {
      extraPackages = with pkgs; [ libvdpau-va-gl ];
      extraPackages32 = with pkgs; [ libvdpau-va-gl ];
    };


  environment.systemPackages = with pkgs; [
    openrgb
    protontricks
    steam.run
    vulkan-tools
    libva-utils
    psensor
    orcaslicer
    liquidctl
  ];

  services.udev.packages = with pkgs; [ 
    liquidctl
    openrgb
  ];
  services.udev.extraRules = ''
    # x52 joystick
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="06a3", ATTRS{idProduct}=="0762", MODE="0666"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="06a3", ATTRS{idProduct}=="0255", MODE="0666"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="06a3", ATTRS{idProduct}=="075c", MODE="0666"
    # relabsd space mouse
    SUBSYSTEM=="input", ATTRS{name}=="relabsd:*", ENV{ID_INPUT_MOUSE}="0", ENV{ID_INPUT_JOYSTICK}="1", ENV{ID_CLASS}="joystick", MODE="0666"
  '';

}

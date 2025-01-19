{ config, pkgs, lib, ... }:
let linuxPackages = pkgs.linuxPackages_latest;
    nvidiaPackage = linuxPackages.nvidiaPackages.beta;
in
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.timeout = 0;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = linuxPackages;
  boot.extraModulePackages = with linuxPackages; [ nct6687d ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.initrd.availableKernelModules = [ "amdgpu" "xhci_pci" "ehci_pci" "ahci" "usbhid" "sd_mod"  "nvme" "nvme_core" ];
  boot.kernelModules = [ "btrfs" "nct6687" ];
  boot.plymouth.enable = true;

  fileSystems."/boot" =
    { device = "/dev/disk/by-label/EFI";
      fsType = "vfat";
      options = [ "relatime" ];
    };
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

  boot.blacklistedKernelModules = [ "nouveau" "bmi160_spi" "bmi160_i2c" "bmi160_core" ];

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

  services.handheld-daemon = {
    enable = true;
    ui.enable = true;
    user = "bara";
  };



  powerManagement.enable = true;
  powerManagement.cpuFreqGovernor = "ondemand";

  #virtualisation.waydroid.enable = true;
  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.hooks.qemu.win10-gpu = ./libvirt-gpu-passthrough-hook.sh;
  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
    storageDriver = "overlay2";
    listenOptions = [ "/run/docker.sock" "0.0.0.0:2375" ];

  };
  hardware.nvidia-container-toolkit.enable = true;
  hardware.nvidia.open = true;

  services.printing = {
    enable = true;
    drivers = [ pkgs.hplip ];
  };

  services.logind.extraConfig = ''
  HandlePowerKey=suspend
  '';

  networking.hostName = "hal";
  networking.firewall.enable = false;
  services.fprintd.enable = true;


  system.stateVersion = "19.09";

  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";

  boot.kernelParams = [
    "quiet"
    "nouveau.modeset=0"
    # allow PCI device pass through
    "amd_iommu=on" "iommu=pt"
    "acpi_enforce_resources=lax"
  ];

  services.xserver.videoDrivers = [ "nvidia" "amdgpu" ];
  hardware.nvidia = {
    modesetting.enable = true;
    package = nvidiaPackage;
    powerManagement.enable = true;
  };
  programs.xwayland.enable = true;
  #programs.alvr.enable = true;
  programs.alvr.openFirewall = true;
  programs.coolercontrol.enable = true;

  nix.settings.max-jobs = lib.mkDefault 8;

  hardware.graphics = {
      extraPackages = with pkgs; [ libvdpau-va-gl ];
      extraPackages32 = with pkgs; [ libvdpau-va-gl ];
    };


  environment.systemPackages = with pkgs; [
    discord-canary
    protontricks
    steam.run
    vulkan-tools
    libva-utils
    # broken https://github.com/NixOS/nixpkgs/issues/369571
    # orca-slicer
    liquidctl
    looking-glass-client
    virtiofsd
    ptouch-print
    gnomeExtensions.dual-shock-4-battery-percentage
    freecad
    offload-game
    egpu
    pywincontrols
  ];

  programs.haguichi.enable = true;

  hardware.sensor.iio.enable = true;

  services.udev.extraRules = ''
    # Avoid wake-up from i2c devices on GPD Win Max 2
    SUBSYSTEM=="i2c", KERNEL=="i2c-PNP0C50:00", ATTR{power/wakeup}="disabled"
    SUBSYSTEM=="i2c", KERNEL=="i2c-GXTP7385:00", ATTR{power/wakeup}="disabled"

    # x52 joystick
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="06a3", ATTRS{idProduct}=="0762", MODE="0666"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="06a3", ATTRS{idProduct}=="0255", MODE="0666"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="06a3", ATTRS{idProduct}=="075c", MODE="0666"

    # relabsd space mouse
    SUBSYSTEM=="input", ATTRS{name}=="relabsd:*", ENV{ID_INPUT_MOUSE}="0", ENV{ID_INPUT_JOYSTICK}="1", ENV{ID_CLASS}="joystick", MODE="0666"

    # Borther P-Touch printers
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="04f9", MODE="0666"

    # preferred GPU for gnome
    ATTRS{vendor}=="0x1002", TAG+="mutter-device-preferred-primary"
    ATTRS{vendor}=="0x10de", TAG+="mutter-device-ignore"

    # Set power limits
    SUBSYSTEM=="power_supply", KERNEL=="ADP1", ATTR{online}=="1", RUN+="${pkgs.ryzenadj}/bin/ryzenadj --stapm-limit 28000 --fast-limit 35000 --slow-limit 32000 --tctl-temp=90"
    SUBSYSTEM=="power_supply", KERNEL=="ADP1", ATTR{online}=="0", RUN+="${pkgs.ryzenadj}/bin/ryzenadj --stapm-limit 15000 --fast-limit 18000 --slow-limit 15000 --tctl-temp=90"
  '';
  services.displayManager.defaultSession = lib.mkForce "gnome";

  systemd.tmpfiles.settings."10-looking-glass" = {
    "/dev/shm/looking-glass".f = {
      group = "libvirtd";
      user = "bara";
      mode = "0660";
    };
  };
  services.switcherooControl.enable = true;
}

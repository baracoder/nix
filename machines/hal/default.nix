{ config, pkgs, lib, ... }:
let linuxPackages = pkgs.linuxPackages_latest;
    nvidiaPackage = linuxPackages.nvidiaPackages.beta;
    nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
        export __NV_PRIME_RENDER_OFFLOAD=1
        #export VK_ICD_FILENAMES=/var/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json
        #export _EGL_VENDOR_LIBRARY_FILENAMES=/var/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json
        export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
        export __VK_LAYER_NV_optimus=NVIDIA_only
        exec "$@"
    '';
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
  fileSystems."/crypt-media" =
    { device = "/dev/disk/by-uuid/99cb6b39-6d94-4cf9-8360-44e90e0e7036";
      fsType = "ext4";
      options = [ "discard" "relatime" ];
    };

  boot.initrd.luks.devices."crypt-ssd".device = "/dev/disk/by-uuid/c822c962-094c-45bc-bb24-ea57062f02a4";
  boot.initrd.luks.devices."crypt-ssd".allowDiscards = true;
  boot.initrd.luks.devices."crypt-media".device = "/dev/disk/by-uuid/ac1082d4-1ce1-48e4-a314-cb8612e45db5";
  boot.initrd.luks.devices."crypt-media".allowDiscards = true;
  boot.initrd.systemd.enable = true;

  boot.blacklistedKernelModules = [ "nouveau" ];

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
  programs.alvr.enable = true;
  programs.coolercontrol.enable = true;

  nix.settings.max-jobs = lib.mkDefault 8;

  hardware.graphics = {
      extraPackages = with pkgs; [ libvdpau-va-gl ];
      extraPackages32 = with pkgs; [ libvdpau-va-gl ];
    };


  environment.systemPackages = with pkgs; [
    protontricks
    steam.run
    vulkan-tools
    libva-utils
    orca-slicer
    liquidctl
    looking-glass-client
    nvidia-offload
    virtiofsd
    ptouch-print
    gnomeExtensions.dual-shock-4-battery-percentage
    jetbrains.rider
    freecad
  ];

  services.udev.extraRules = ''
    # x52 joystick
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="06a3", ATTRS{idProduct}=="0762", MODE="0666"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="06a3", ATTRS{idProduct}=="0255", MODE="0666"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="06a3", ATTRS{idProduct}=="075c", MODE="0666"

    # relabsd space mouse
    SUBSYSTEM=="input", ATTRS{name}=="relabsd:*", ENV{ID_INPUT_MOUSE}="0", ENV{ID_INPUT_JOYSTICK}="1", ENV{ID_CLASS}="joystick", MODE="0666"

    # Borther P-Touch printers
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="04f9", MODE="0666"

    # preferred GPU for gnome
    ENV{ID_PATH}=="pci-0000:0c:00.0", TAG+="mutter-device-preferred-primary"
    ENV{ID_PATH}=="pci-0000:01:00.0", TAG+="mutter-device-ignore"
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

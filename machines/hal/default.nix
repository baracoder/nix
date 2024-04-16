{ config, pkgs, lib, ... }:
let linuxPackages = pkgs.linuxPackages_zen;
    nvidiaPackage = linuxPackages.nvidiaPackages.latest;
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
  boot.loader.timeout = null;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = linuxPackages;
  boot.extraModulePackages = with linuxPackages; [ asus-wmi-sensors v4l2loopback ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.initrd.availableKernelModules = [ "amdgpu" "xhci_pci" "ehci_pci" "ahci" "usbhid" "sd_mod"  "nvme" "nvme_core" ];
  boot.kernelModules = [ "btrfs" "v4l2loopback"  ];
  boot.plymouth.enable = true;

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/4B1E-8899";
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

  boot.blacklistedKernelModules = ["nvidia_drm" "nvidia_uvm" "nvidia_modeset" "nvidia"];

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

  system.stateVersion = "19.09";

  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";

  boot.kernelParams = [
    "quiet"
    "nouveau.modeset=0"
    # workaround for nvidia docker
    "systemd.unified_cgroup_hierarchy=false" 
    # allow PCI device pass through
    "amd_iommu=on" "iommu=pt"
  ];

  services.xserver.videoDrivers = [ "nvidia" "amdgpu" ];
  hardware.nvidia = {
    modesetting.enable = true;
    package = nvidiaPackage;
    powerManagement.enable = true;
  };
  programs.xwayland.enable = true;
  programs.coolercontrol.enable = true;
  # coolercontrold might load nvidia modules. Make it wait for libvirtd to start the VM
  systemd.services.coolercontrold = {
    path = [ nvidiaPackage pkgs.bash pkgs.libglvnd nvidiaPackage.settings ];
    environment.LD_LIBRARY_PATH = "${pkgs.libglvnd}/lib";
    after = [ "wait-win10.service" ];
    wants = [ "wait-win10.service" ];
  };
  systemd.services."wait-win10" = {
      serviceConfig.Type = "oneshot";
      serviceConfig.RemainAfterExit="yes";
      enable = true;
      path = [ pkgs.libvirt pkgs.bash ];
      script = ''
        timeout 15 bash -c 'until virsh -c qemu:///system list --state-running|grep win10; do sleep 1; done'
      '';
  };

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
    orca-slicer
    liquidctl
    looking-glass-client
    nvidia-offload
    virtiofsd
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

    # NZXT RGB & Fan Controller (3+6 channels)
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="1e71", ATTRS{idProduct}=="2019", TAG+="uaccess"

    # preferred GPU
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

  programs.haguichi.enable = true;
  services.logmein-hamachi.enable = true;
}

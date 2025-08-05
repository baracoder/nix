{
  config,
  pkgs,
  lib,
  ...
}:
let
  linuxPackages = pkgs.linuxPackages_zen;
  nvidiaPackage = linuxPackages.nvidiaPackages.beta;
  gpd-fan = config.boot.kernelPackages.callPackage ../../pkgs/gpd-fan { };
in
{
  imports = [
    ./filesystems.nix
    ./nebula.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.timeout = 0;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = linuxPackages;
  boot.extraModulePackages = with linuxPackages; [
    acpi_call
    gpd-fan
  ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.initrd.availableKernelModules = [
    "amdgpu"
    "xhci_pci"
    "ehci_pci"
    "ahci"
    "usbhid"
    "sd_mod"
    "nvme"
    "nvme_core"
    "nvidia"
  ];
  boot.kernelModules = [
    "btrfs"
    "acpi_call"
    "gpd_fan"
  ];
  boot.plymouth.enable = true;
  boot.plymouth.extraConfig = ''
    DeviceScale=2
  '';

  boot.initrd.systemd.enable = true;

  boot.blacklistedKernelModules = [
    "nouveau"
    "bmi160_spi"
    "bmi160_i2c"
    "bmi160_core"
  ];
  boot.extraModprobeConfig = ''
    options bluetooth disable_ertm=1
  '';

  systemd.generators.systemd-gpt-auto-generator = "/dev/null";

  hardware.cpu.amd.updateMicrocode = true;
  hardware.bluetooth.enable = true;
  hardware.steam-hardware.enable = true;

  services.handheld-daemon = {
    enable = true;
    ui.enable = true;
    user = "bara";
    package =
      with pkgs;
      handheld-daemon.overrideAttrs (oldAttrs: {
        propagatedBuildInputs = oldAttrs.propagatedBuildInputs ++ [
          pkgs.adjustor
        ];
      });
  };

  services.power-profiles-daemon.enable = true; # Power management is handled by handheld-daemon adjustor
  powerManagement.cpuFreqGovernor = "ondemand";

  #virtualisation.waydroid.enable = true;
  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.hooks.qemu.win10-gpu = ./libvirt-gpu-passthrough-hook.sh;
  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
    storageDriver = "overlay2";
    listenOptions = [
      "/run/docker.sock"
      "0.0.0.0:2375"
    ];

  };
  hardware.nvidia.open = true;

  services.printing = {
    enable = true;
    drivers = [ pkgs.brlaser ];
  };

  services.ollama = {
    enable = true;
    #acceleration = "rocm";
  };
  #services.open-webui.enable = true;
  #services.open-webui.host = "0.0.0.0";

  services.logind.extraConfig = ''
    HandlePowerKey=suspend
  '';

  networking.hostName = "hal";
  networking.firewall.enable = false;
  services.fprintd.enable = false;
  #systemd.services.fprintd = {
  #  conflicts = [ "sleep.target" "suspend.target" "hybernante.target" ];
  #};

  system.stateVersion = "19.09";

  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";

  boot.kernelParams = [
    "quiet"
    "nouveau.modeset=0"
    # allow PCI device pass through
    "amd_iommu=on"
    "iommu=pt"
    "acpi_enforce_resources=lax"
    "bluetooth.disable_ertm=1" # bluetooth gamepad compatibility
  ];

  services.xserver.videoDrivers = [
    "nvidia"
    "amdgpu"
  ];
  hardware.nvidia = {
    modesetting.enable = true;
    package = nvidiaPackage;
    powerManagement.enable = true;
  };
  programs.xwayland.enable = true;
  programs.coolercontrol.enable = true;

  nix.settings.max-jobs = lib.mkDefault 8;

  hardware.graphics = {
    extraPackages = with pkgs; [ libvdpau-va-gl ];
    extraPackages32 = with pkgs; [ libvdpau-va-gl ];
  };

  # Workaround for LG Ultrawide stuttering on playback resume
  services.pipewire.wireplumber.extraConfig = {
    "hdmi-screen" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            {
              "node.name" = "~alsa_output.*hdmi*";
            }
          ];
          actions = {
            update-props = {
              "session.suspend-timeout-seconds" = 0;
            };
          };
        }
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    piper-tts
    easyeffects
    discord
    freecad
    vulkan-tools
    libva-utils
    # broken https://github.com/NixOS/nixpkgs/issues/369571
    # orca-slicer
    liquidctl
    looking-glass-client
    virtiofsd
    ptouch-print
    nebula
    pywincontrols
    nh
    hifiscan
    fprintd
    pyroveil
    vial
    vivaldi
    arduino-ide
  ];

  hardware.sensor.iio.enable = true;
  hardware.enableRedistributableFirmware = true;

  services.udev.extraRules = ''
    # Avoid wake-up from i2c devices on GPD Win Max 2
    SUBSYSTEM=="i2c", KERNEL=="i2c-PNP0C50:00", ATTR{power/wakeup}="disabled"
    SUBSYSTEM=="i2c", KERNEL=="i2c-GXTP7385:00", ATTR{power/wakeup}="disabled"

    # Disable fprint scanner
    SUBSYSTEM=="usb", ATTR{idVendor}=="2541", ATTR{idProduct}=="9711", ATTR{remove}="1"

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
  '';
  services.udev.packages = [
    pkgs.vial
  ];
  services.displayManager.defaultSession = lib.mkForce "gnome";

  systemd.tmpfiles.settings."10-looking-glass" = {
    "/dev/shm/looking-glass".f = {
      group = "libvirtd";
      user = "bara";
      mode = "0660";
    };
  };

  systemd.services.systemd-vconsole-setup.unitConfig.After = "local-fs.target";

}

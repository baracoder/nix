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

  services.udev.extraRules = ''
    # UDEV Rules for PlatformIO supported boards, http://platformio.org/boards
    #
    # The latest version of this file may be found at:
    # 	https://github.com/platformio/platformio-core/blob/develop/scripts/99-platformio-udev.rules
    #
    # This file must be placed at:
    # 	/etc/udev/rules.d/99-platformio-udev.rules    (preferred location)
    #   	or
    # 	/lib/udev/rules.d/99-platformio-udev.rules    (req'd on some broken systems)
    #
    # To install, type this command in a terminal:
    # 	sudo cp 99-platformio-udev.rules /etc/udev/rules.d/99-platformio-udev.rules
    #
    # Restart "udev" management tool:
    #	sudo service udev restart
    #		or
    # 	sudo udevadm control --reload-rules
    #	sudo udevadm trigger
    #
    # After this file is installed, physically unplug and reconnect your board.

    # CP210X USB UART
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE:="0666"

    # FT232R USB UART
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", MODE:="0666"

    # Prolific Technology, Inc. PL2303 Serial Port
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="067b", ATTRS{idProduct}=="2303", MODE:="0666"

    # QinHeng Electronics HL-340 USB-Serial adapter
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", MODE:="0666"

    # Arduino boards
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="[08][02]*", MODE:="0666"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2a03", ATTRS{idProduct}=="[08][02]*", MODE:="0666"

    # Arduino SAM-BA
    ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="6124", ENV{ID_MM_DEVICE_IGNORE}="1"
    ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="6124", ENV{MTP_NO_PROBE}="1"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="6124", MODE:="0666"
    KERNEL=="ttyACM*", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="6124", MODE:="0666"

    # Digistump boards
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="16d0", ATTRS{idProduct}=="0753", MODE:="0666"
    KERNEL=="ttyACM*", ATTRS{idVendor}=="16d0", ATTRS{idProduct}=="0753", MODE:="0666", ENV{ID_MM_DEVICE_IGNORE}="1"

    # STM32 discovery boards, with onboard st/linkv2
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374?", MODE:="0666"

    # USBtiny
    SUBSYSTEMS=="usb", ATTRS{idProduct}=="0c9f", ATTRS{idVendor}=="1781", MODE="0666"

    # Teensy boards
    ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789]?", ENV{ID_MM_DEVICE_IGNORE}="1"
    ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789]?", ENV{MTP_NO_PROBE}="1"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789]?", MODE:="0666"
    KERNEL=="ttyACM*", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789]?", MODE:="0666"

    #TI Stellaris Launchpad
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="1cbe", ATTRS{idProduct}=="00fd", MODE="0666"

    #TI MSP430 Launchpad
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0451", ATTRS{idProduct}=="f432", MODE="0666"

    # CMSIS-DAP compatible adapters
    ATTRS{product}=="*CMSIS-DAP*", MODE="664", GROUP="plugdev"
  '';
}

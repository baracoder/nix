{ config, lib, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.timeout = 0;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.plymouth.enable = true;

  boot.kernelParams = [
    "nopti"
    "mem_sleep_default=s2idle"
    "nvme.noacpi=1"
    # Workaround: https://gitlab.freedesktop.org/drm/intel/-/issues/6757#note_1602653
    "i915.enable_psr=0"
    "i915.enable_dc=0"
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
    jetbrains.datagrip
    jetbrains.rider
  ];
  # power management
  #services.thermald.enable = true;
  #services.tlp.enable = false;
  #powerManagement = {
  #  enable = true;
  #  cpuFreqGovernor = "powersave";
  #};
  powerManagement.powertop.enable = true;

  programs.nix-ld.enable = true;

  hardware.opengl = {
      enable = true;
      extraPackages = with pkgs; [ vaapiIntel libvdpau-va-gl ];
      extraPackages32 = with pkgs; [ vaapiIntel libvdpau-va-gl ];
    };
  hardware.video.hidpi.enable = true;



  virtualisation.docker.enable = true;
  virtualisation.docker.extraOptions = "--bip 172.30.0.1/16 --default-address-pool=base=172.30.0.0/16,size=24 --default-address-pool=base=172.40.1.0/16,size=24";
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


  networking.extraHosts = ''
# AD hosts Intercars
#10.123.250.33 dcinter01.intercars.local dcinter01
#10.123.250.35 dcinter02.intercars.local dcinter02
#10.123.250.41 dcinter03.intercars.local dcinter03
#10.123.250.40 dcinter04.intercars.local dcinter04
#10.123.250.32 dcic03.ic dcic03
#10.123.250.34 dcic04.ic dcic04
#10.123.250.38 dcic05.ic dcic05
#10.123.250.39 dcic06.ic dcic06
##CDP Stage environment
#10.125.3.4 cdp-stage-ldr-4.intercars.local cdp-stage-ldr-4
#10.125.3.5 cdp-stage-ldr-5.intercars.local cdp-stage-ldr-5
#10.125.3.6 cdp-stage-ldr-6.intercars.local cdp-stage-ldr-6
## CDP prod environment
#10.123.15.207 cdp-prod-ldr-1.intercars.local cdp-prod-ldr-1
#10.123.15.208 cdp-prod-ldr-2.intercars.local cdp-prod-ldr-2
#10.123.15.209 cdp-prod-ldr-3.intercars.local cdp-prod-ldr-3

10.123.250.33   dcinter01.intercars.local       dcinter01
10.123.250.35   dcinter02.intercars.local       dcinter02
10.123.250.41   dcinter03.intercars.local       dcinter03
10.123.250.40   dcinter04.intercars.local       dcinter04
10.123.250.32   dcic03.ic       dcic03
10.123.250.34   dcic04.ic       dcic04
10.123.250.38   dcic05.ic       dcic05
10.123.250.39   dcic06.ic       dcic06
10.123.15.207   cdp-prod-ldr-1  cdp-prod-ldr-1.intercars.local
10.123.15.208   cdp-prod-ldr-2  cdp-prod-ldr-2.intercars.local
10.123.15.209   cdp-prod-ldr-3  cdp-prod-ldr-3.intercars.local
  '';

}

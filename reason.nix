{ config, pkgs, ... }:

{
  #nix.extraOptions = ''
  #  netrc-file = /etc/nix/netrc
  #  build-sandbox-paths = /etc/nix/netrc
  #'';
  nix.sandboxPaths = [
    "/dev/nvidia0"
    "/dev/nvidiactl"
    "/dev/nvidia-modeset"
    "/dev/nvidia-uvm"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    firewall.enable = false;
    hostName = "reason";
    networkmanager.enable = false;
    bridges.bridge0 = {
      interfaces = [ "enp6s0" ];
    };
    defaultGateway = {
      address = "192.168.0.1";
      interface = "bridge0";
    };
    dhcpcd.enable = false;
    nameservers = [
      "192.168.0.1"
    ];
    search = [ "fritz.box" ];
    interfaces.bridge0.ipv4.addresses = [{
      address = "192.168.0.32";
      prefixLength = 24;
    }] ;
  };


  environment.systemPackages = with pkgs; [
  ];
  virtualisation.docker = {
    enable = true;
    storageDriver = "btrfs";
    autoPrune.enable = true;
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  system.stateVersion = "17.09";
  powerManagement.powerUpCommands="/var/run/current-system/sw/sbin/hdparm -S 120 /dev/sd[a-z]";
  services.teamviewer.enable = true;

  # btrfs stuff
  systemd.services.btrfs-cleanup = {
    script = ''
      ${pkgs.duperemove}/bin/duperemove -hrd /home
      ${pkgs.duperemove}/bin/duperemove -hrd /nix
      ${pkgs.btrfsProgs}/bin/btrfs filesystem defragment -czstd -r /home
    '';
    serviceConfig = {
      Type = "oneshot";
    };
  };
  systemd.timers.btrfs-cleanup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
    };
  };
  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/" ];
  };
  services.xserver.displayManager.gdm.wayland = false;
}

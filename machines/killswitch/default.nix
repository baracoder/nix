{
  pkgs,
  lib,
  ...
}:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.timeout = 0;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_6_12;
  boot.kernelModules = [
    "btrfs"
  ];
  boot.plymouth.enable = true;

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/49F6-64A7";
    fsType = "vfat";
    options = [ "relatime" ];
  };
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/f5e1e485-0f60-49af-bebc-1028d7f1029c";
    fsType = "btrfs";
    options = [
      "discard=async"
      "relatime"
      "subvol=root"
      "compress=lzo"
    ];
  };
  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/f5e1e485-0f60-49af-bebc-1028d7f1029c";
    fsType = "btrfs";
    options = [
      "discard=async"
      "relatime"
      "subvol=home"
      "compress=lzo"
    ];
  };
  swapDevices = [
    {
      device = "/dev/mapper/crypt-swap";
    }
  ];

  boot.initrd.luks.devices."crypt-ssd" = {
    device = "/dev/disk/by-uuid/de560dc1-9178-4ba0-8ac9-bf4fa40a7ed8";
    allowDiscards = true;
  };
  boot.initrd.luks.devices."crypt-swap" = {
    device = "/dev/disk/by-uuid/afca4682-64fe-490e-bf7b-2b532f2a437e";
  };
  boot.initrd.systemd.enable = true;

  systemd.generators.systemd-gpt-auto-generator = "/dev/null";

  hardware.bluetooth.enable = true;
  hardware.enableRedistributableFirmware = true;
  hardware.firmware = [ pkgs.sof-firmware ];

  services.xserver.videoDrivers = [ "intel" ];

  powerManagement.cpuFreqGovernor = "ondemand";

  virtualisation.docker = {
    enable = true;
    enableOnBoot = false; # use socket activation
    storageDriver = "overlay2";
  };

  services.ollama = {
    enable = true;
  };

  services.logind.settings.Login.HandlePowerKey = "suspend";

  networking.hostName = "killswitch";

  system.stateVersion = "25.05";

  programs.xwayland.enable = true;

  programs._1password.enable = true;
  programs._1password-gui.enable = true;
  programs._1password-gui.polkitPolicyOwners = [ "bara" ];

  nix.settings.max-jobs = lib.mkDefault 8;

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

  services.cloudflare-warp.enable = true;
  services.fprintd.enable = true;

  environment.systemPackages = with pkgs; [
    awscli2
    colima
    direnv
    easyeffects
    eksctl
    fprintd
    fzf
    gh
    gitFull
    hifiscan
    htop
    jq
    jujutsu
    k9s
    kaf
    kcat
    kubectl
    kubernetes-helm
    kustomize
    meld
    nebula
    nh
    slack
    tfswitch
    valkey
    vial
    vivaldi
    wireshark
    yarn
  ];

  services.udev.packages = [
    pkgs.vial
  ];

}

{
  pkgs,
  lib,
  ...
}:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.timeout = 0;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernelModules = [
    "btrfs"
  ];
  boot.plymouth.enable = true;

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/EFI";
    fsType = "vfat";
    options = [ "relatime" ];
  };
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/??";
    fsType = "btrfs";
    options = [
      "discard=async"
      "relatime"
      "subvol=root"
      "compress=lzo"
    ];
  };
  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/??";
    fsType = "btrfs";
    options = [
      "discard=async"
      "relatime"
      "subvol=home"
      "compress=lzo"
    ];
  };

  boot.initrd.luks.devices."crypt-ssd".device =
    "/dev/disk/by-uuid/c822c962-094c-45bc-bb24-ea57062f02a4";
  boot.initrd.luks.devices."crypt-ssd".allowDiscards = true;
  boot.initrd.systemd.enable = true;

  systemd.generators.systemd-gpt-auto-generator = "/dev/null";

  hardware.bluetooth.enable = true;

  powerManagement.cpuFreqGovernor = "ondemand";

  virtualisation.docker = {
    enable = true;
    enableOnBoot = false; # use socket activation
    storageDriver = "overlay2";
  };

  services.printing = {
    enable = true;
    drivers = [ pkgs.brlaser ];
  };

  services.ollama = {
    enable = true;
  };

  services.logind.extraConfig = ''
    HandlePowerKey=suspend
  '';

  networking.hostName = "killswitch";

  system.stateVersion = "25.05";

  programs.xwayland.enable = true;

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

  environment.systemPackages = with pkgs; [
    _1password-cli
    awscli2
    colima
    direnv
    easyeffects
    eksctl
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
    lazyjj
    meld
    nebula
    nh
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

{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.vds;
in
{
  options.services.vds = {
    enable = lib.mkEnableOption ''
      vDS, which bridges Bluetooth DualSense controllers to virtual USB
      DualSense devices (haptics, adaptive triggers, speaker, mic).

      This disables BlueZ's input plugin, so no other Bluetooth HID device
      (keyboard, mouse, gamepad) will work while it is on'';

    package = lib.mkPackageOption pkgs "vds" { };

    maxPorts = lib.mkOption {
      type = lib.types.ints.between 1 4;
      default = 4;
      description = "Number of virtual USB ports (controllers) vds_hcd exposes.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    boot.extraModulePackages = [
      (config.boot.kernelPackages.callPackage ./kmod.nix { vds = cfg.package; })
    ];
    boot.kernelModules = [ "vds_hcd" ];
    boot.extraModprobeConfig = ''
      options vds_hcd max_port=${toString cfg.maxPorts}
    '';

    # vdsd needs to own the HID Control/Interrupt L2CAP channels itself.
    hardware.bluetooth.disabledPlugins = [ "input" ];

    # Touchpad-as-external udev rule; WirePlumber naming/4ch layout for the
    # haptics sink and passive mic source.
    services.udev.packages = [ cfg.package ];
    services.pipewire.wireplumber.configPackages = [ cfg.package ];

    systemd.services.vdsd = {
      description = "vDS userspace daemon";
      # No ExecStartPre=modprobe like upstream's unit: boot.kernelModules loads
      # vds_hcd, and NixOS modprobe only searches /run/booted-system, so it
      # fails after the switch that first adds the module. vdsd tolerates the
      # module being absent and picks up /dev/vds* ports via udev.
      after = [
        "bluetooth.service"
        "systemd-modules-load.service"
      ];
      wants = [ "bluetooth.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${lib.getExe' cfg.package "vdsd"} --db-path /var/lib/vds/vdsd.db --log /var/log/vds/vdsd.log";
        Restart = "on-failure";
        RestartSec = "1s";
        StateDirectory = "vds";
        LogsDirectory = "vds";
      };
    };

    services.logrotate.settings.vdsd = {
      files = "/var/log/vds/vdsd.log";
      frequency = "weekly";
      rotate = 4;
      missingok = true;
      notifempty = true;
      compress = true;
      delaycompress = true;
      postrotate = "systemctl kill -s HUP vdsd.service >/dev/null 2>&1 || true";
    };
  };
}

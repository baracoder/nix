{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.linzone-hub;
in
{
  options.programs.linzone-hub = {
    enable = lib.mkEnableOption "LINZONE Hub, a controller for Sony INZONE devices";

    package = lib.mkPackageOption pkgs "linzone-hub" { };

    batteryModule.enable =
      lib.mkEnableOption "the hid_inzone_battery kernel module, which exposes INZONE batteries to UPower"
      // {
        default = true;
      };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    # hidraw/tty access for the active seat, ModemManager exclusion for the
    # H9/H7 CDC ACM port, and UPower battery types for the module's supplies.
    services.udev.packages = [ cfg.package ];

    # The module carries a HID device table, so udev autoloads it on plug-in.
    boot.extraModulePackages = lib.mkIf cfg.batteryModule.enable [
      (config.boot.kernelPackages.callPackage ./kmod.nix { linzone-hub = cfg.package; })
    ];
  };
}

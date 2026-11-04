{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.ionwl;
in
{
  options.programs.ionwl = {
    enable = lib.mkEnableOption "the IonWL compositor as a display manager session";

    package = lib.mkPackageOption pkgs "ionwl" { };

    primaryGpu = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/dev/dri/by-path/pci-0000:c4:00.0-card";
      description = ''
        DRM device ionwl renders on and offers to clients. ionwl cannot render
        across GPUs, so this must be the GPU driving the displays; otherwise
        window contents stay blank.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.displayManager.sessionPackages = [ cfg.package ];

    environment.sessionVariables = lib.mkIf (cfg.primaryGpu != null) {
      IONWL_PRIMARY_GPU = cfg.primaryGpu;
    };

    environment.systemPackages = with pkgs; [
      cfg.package
      # shell: bar, launcher, notifications; run one of the two shells,
      # both own the notification daemon name
      noctalia
      way-shell
      fuzzel
      # outputs, via wlr-output-management
      wlr-randr
      kanshi
      wdisplays
      # screenshots, via wlr-screencopy
      grim
      slurp
      wl-clipboard
    ];

    # ionwl sets XDG_CURRENT_DESKTOP=ionwl; screen sharing goes through
    # wlr-screencopy, everything else through the GTK portal.
    xdg.portal = {
      extraPortals = [ pkgs.xdg-desktop-portal-wlr ];
      config.ionwl = {
        default = [ "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
      };
    };
  };
}

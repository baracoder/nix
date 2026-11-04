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

    # ionwl only exports its environment to systemd; this target is what
    # activates graphical-session.target, without which the desktop portal
    # (and so GTK settings like the icon theme) refuses to start.
    # ion_init.py starts it on startup and stops it on shutdown.
    systemd.user.targets.ionwl-session = {
      description = "ionwl compositor session";
      documentation = [ "man:systemd.special(7)" ];
      bindsTo = [ "graphical-session.target" ];
      wants = [ "graphical-session-pre.target" ];
      after = [ "graphical-session-pre.target" ];
    };

    environment.sessionVariables = lib.mkIf (cfg.primaryGpu != null) {
      IONWL_PRIMARY_GPU = cfg.primaryGpu;
    };

    # Lock screen, via ext-session-lock. ion_init.py locks through
    # `loginctl lock-session`, which ionwl-lockd turns into gtklock; it
    # also locks before suspend.
    programs.gtklock = {
      enable = true;
      config.main.idle-hide = true;
      modules = with pkgs; [
        gtklock-userinfo-module
        gtklock-powerbar-module
      ];
    };

    # dux-shell (`dms run`): its nixpkgs module adds quickshell, matugen and
    # cava. Started from ion_init.py rather than by its unit, which would
    # start it in every graphical session, next to the other shells.
    programs.dux-shell = {
      enable = true;
      systemd.enable = false;
    };

    environment.systemPackages = with pkgs; [
      cfg.package
      # shell: bar, launcher, notifications; run one shell at a time, all
      # own the notification daemon name
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
      # lock screen trigger, see above
      ionwl-lockd
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

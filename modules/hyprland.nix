{ config, pkgs, inputs, lib, ... }:

let cfg = config.myHyprland;
in {

  options.myHyprland = {
    enable = lib.mkEnableOption "Enable configuration for using hyprland";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      hyprpaper
      fuzzel
      networkmanagerapplet
      polybarFull
      playerctl
      gsettings-desktop-schemas
      nwg-bar
      nwg-dock
      nwg-panel
      nwg-drawer
      nwg-displays
      gtklock
      gtklock-userinfo-module
      gtklock-powerbar-module
      gtklock-playerctl-module
      wlr-randr
      swaynotificationcenter
      lxappearance
      gsettings-desktop-schemas
      gnome.adwaita-icon-theme
      gtk3
      blueman
      swayidle
      gopsuinfo
      swayosd
      gnome.nautilus
      xfce.thunar
      flameshot
      grim
      slurp
      swappy
      wl-clipboard
      alacritty
      kitty
      gnome3.eog

    ];

    services.xserver.desktopManager.gnome.enable = false; # still not compatible
    services.xserver.displayManager.defaultSession = "hyprland";
    xdg.portal.extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];

    systemd.packages = with pkgs; [
      swayosd
    ];


    programs.dconf.enable = true;
    services.blueman.enable = true;
    programs.hyprland = {
      enable = false;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    };
    networking.networkmanager.enable = true;
    security.pam.services.gtklock = {};
    qt.style = "adwaita-dark";
    environment.etc = {
      "xdg/gtk-3.0/settings.ini".text = ''
        [Settings]
        gtk-application-prefer-dark-theme=1
      '';
      "xdg/gtk-4.0/settings.ini".text = ''
        [Settings]
        gtk-application-prefer-dark-theme=1
      '';
    };
  };
}

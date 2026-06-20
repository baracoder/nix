{
  pkgs,
  lib,
  ...
}:
let
  xkbVariant = "us+altgr-intl"; # no dead keys
  xkbOptions = [
    "eurosign:e"
    "compose:menu"
    "lv3:caps_switch"
  ];
in
{
  services.gnome = {
    gnome-browser-connector.enable = true;
    gnome-keyring.enable = true;
    gnome-online-accounts.enable = true;
    #gnome-user-share.enable = true;
    localsearch.enable = true;
    tinysparql.enable = true;
    sushi.enable = true;
    at-spi2-core.enable = true;
  };
  services.desktopManager.gnome = {
    enable = true;
    extraGSettingsOverridePackages = [ pkgs.mutter ];
    extraGSettingsOverrides = ''
      [org.gnome.desktop.input-sources]
      sources=[('xkb', '${xkbVariant}')]
      xkb-options=['${lib.concatStringsSep "', '" xkbOptions}']
    '';
  };

  programs.gnome-terminal.enable = true;
  programs.gnome-disks.enable = true;

  environment.systemPackages = with pkgs.gnomeExtensions; [
    appindicator
    astra-monitor
    auto-move-windows
    battery-time-2
    bing-wallpaper-changer
    bluetooth-battery-meter
    caffeine
    notification-timeout
    quick-settings-audio-devices-hider
    quick-settings-audio-devices-renamer
    steal-my-focus-window
    steal-my-focus-window
    tiling-assistant
    weeks-start-on-monday-again
    windownavigator
    pkgs.gnome-extension-tts-baracoder
  ];

  # Workaround for recording indicator
  #  until https://gitlab.gnome.org/GNOME/gnome-shell/-/work_items/7217 is resolved
  nixpkgs.overlays = [
    (final: prev: {
      gnome-shell = prev.gnome-shell.overrideAttrs (a: {
        patches = a.patches ++ [
          ./0001-volume-only-show-mic-indicator-for-running-streams.patch
        ];
      });
    })
  ];

}

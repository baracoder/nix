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

  environment.systemPackages =
    with pkgs.gnomeExtensions;
    [
      appindicator
      astra-monitor
      battery-time-2
      bing-wallpaper-changer
      bluetooth-battery-meter
      notification-timeout
      quick-settings-audio-devices-hider
      quick-settings-audio-devices-renamer
      steal-my-focus-window
      steal-my-focus-window
      tiling-assistant
      weeks-start-on-monday-again
      (voluble.overrideAttrs (a: {
        # Mute notifications by default
        postInstall = ''
          sed -i 's/unmuted = true/unmuted = false/g' $out/share/gnome-shell/extensions/voluble@quantiusbenignus.local/extension.js
        '';

      }))
    ]
    ++ [
      (pkgs.gnome44Extensions."gestureImprovements@gestures".overrideAttrs (a: {
        postInstall = ''
          sed -i 's/"42"/"47"/' $out/share/gnome-shell/extensions/gestureImprovements@gestures/metadata.json
        '';
      }))
    ];
}

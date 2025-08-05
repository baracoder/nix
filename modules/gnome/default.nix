{
  pkgs,
  ...
}:
let
  xkbVariant = "altgr-intl"; # no dead keys
  xkbOptions = "eurosign:e,compose:menu,lv3:caps_switch";
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
      xkb-options=['${xkbOptions}']
    '';
  };

  programs.gnome-terminal.enable = true;
  programs.gnome-disks.enable = true;

  environment.systemPackages =
    with pkgs.gnomeExtensions;
    [
      quick-settings-audio-devices-hider
      appindicator
      bing-wallpaper-changer
      bluetooth-quick-connect
      astra-monitor
      tiling-assistant
      weeks-start-on-monday-again
      battery-time-2
      steal-my-focus-window
      notification-timeout
      voluble
    ]
    ++ [
      (pkgs.gnome44Extensions."gestureImprovements@gestures".overrideAttrs (a: {
        postInstall = ''
          sed -i 's/"42"/"47"/' $out/share/gnome-shell/extensions/gestureImprovements@gestures/metadata.json
        '';
      }))
    ];
}

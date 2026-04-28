{
  pkgs,
  vibepanel,
  ...
}:
{

  environment.systemPackages = with pkgs; [
    xwayland-satellite
    noctalia-shell
    kanshi
    playerctl
    ashell
    # dms-shell
    # quickshell
    walker
    anyrun
    fnott
    vibepanel.packages.${stdenv.hostPlatform.system}.default
  ];

  programs.niri.enable = true;
}

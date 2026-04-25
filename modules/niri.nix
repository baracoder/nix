{
  pkgs,
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
    fnott
  ];

  programs.niri.enable = true;
}

{ pkgs, ... }:
{
  systemPackages = with pkgs; [
    xwayland-satellite
    noctalia-shell
  ];

  programs.niri.enable = true;
}

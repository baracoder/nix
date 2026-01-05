{ pkgs, ... }:
{

  services.switcherooControl.enable = true;
  programs.steam.enable = true;
  programs.gamescope.enable = true;
  programs.steam.gamescopeSession.enable = true;
  programs.steam.remotePlay.openFirewall = true;

  # vr
  programs.alvr.enable = true;
  services.wivrn.enable = true;

  environment.systemPackages = with pkgs; [
    beyond-all-reason
    bs-manager
    egpu
    min-ed-launcher
    offload-game
    protontricks
    steam.run
    wlx-overlay-s
  ];
}

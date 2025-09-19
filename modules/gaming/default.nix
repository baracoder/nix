{ pkgs, ... }:
{

  services.switcherooControl.enable = true;
  programs.steam.enable = true;
  programs.gamescope.enable = true;
  programs.steam.gamescopeSession.enable = true;

  # vr
  programs.alvr.enable = true;
  services.wivrn.enable = true;

  environment.systemPackages = with pkgs; [
    beyond-all-reason
    egpu
    offload-game
    protontricks
    steam.run
    wlx-overlay-s
  ];
}

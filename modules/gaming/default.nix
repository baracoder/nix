{ pkgs, ... }:
{

  services.switcherooControl.enable = true;
  programs.steam.enable = true;
  programs.gamescope.enable = true;
  programs.steam.gamescopeSession.enable = true;
  programs.steam.remotePlay.openFirewall = true;
  programs.steam.extest.enable = true;

  # vr
  services.wivrn.enable = true;
  services.wivrn.openFirewall = true;

  environment.systemPackages = with pkgs; [
    beyond-all-reason
    bs-manager
    egpu
    min-ed-launcher
    offload-game
    protontricks
    steam.run
    wayvr
  ];
}

# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./host.nix
      ./common-packages.nix
    ];


  hardware.opengl.driSupport32Bit = true;


  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "us";
    defaultLocale = "en_US.UTF-8";
  };

  time.timeZone = "Europe/Berlin";



  fonts = {
    enableFontDir = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
      terminus_font
      corefonts
      inconsolata
      ubuntu_font_family
      unifont
    ];
  };

  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
    package = pkgs.pulseaudioFull;
  };

  services = {
    avahi = {
      enable = true;
      nssmdns = true;
    };
    openssh.enable = true;
    printing.enable = true;
    xserver.enable = true;
    xserver.layout = "us";
    xserver.xkbOptions = "eurosign:e";
    xserver.displayManager.slim = {
      enable = true;
      autoLogin = true;
      defaultUser = "bara";
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.bara = {
    isNormalUser = true;
    uid = 1000;
    group = "bara";
    extraGroups = [ "video" "wheel" "adm" "audio" "docker" ];
    createHome = true;
    shell = "/run/current-system/sw/bin/zsh";
  };
  users.extraGroups.bara.gid = 1000;


}

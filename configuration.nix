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

  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;

  hardware.enableKSM = true;


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
      terminus_font_ttf
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
    openssh.forwardX11 = true;
    udisks2.enable = true;
    printing.enable = true;
    xserver = {
      enable = true;
      layout = "us";
      xkbOptions = "eurosign:e";
      windowManager.default = "i3";
      desktopManager.default = "gnome3";
      displayManager.lightdm = {
        enable = true;
      #  autoLogin = {
      #    enable = true;
      #    user = "bara";
      #  };
      };
      windowManager.i3.enable = true;
      desktopManager.gnome3.enable = true;
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.bara = {
    isNormalUser = true;
    uid = 1000;
    group = "bara";
    extraGroups = [ "users" "video" "wheel" "adm" "audio" "docker" "input" "vboxusers" "adbusers" "libvirtd" ];
    createHome = true;
    shell = "/run/current-system/sw/bin/zsh";
  };
  users.extraGroups.bara.gid = 1000;


  environment.systemPackages = with pkgs; [
    pkgs.steamcontroller-udev-rules
  ];

  # steam controller udev rule
  nixpkgs.config.packageOverrides = pkgs: {
    steamcontroller-udev-rules = pkgs.writeTextFile {
      name = "steamcontroller-udev-rules";
      text = ''
# This rule is needed for basic functionality of the controller in Steam and keyboard/mouse emulation
SUBSYSTEM=="usb", ATTRS{idVendor}=="28de", MODE="0666"
#
# # This rule is necessary for gamepad emulation; make sure you replace 'users' with a group that the user that runs Steam belongs to
KERNEL=="uinput", MODE="0660", GROUP="users", OPTIONS+="static_node=uinput"
#
# # Valve HID devices over USB hidraw
KERNEL=="hidraw*", ATTRS{idVendor}=="28de", MODE="0666"
#
# # Valve HID devices over bluetooth hidraw
KERNEL=="hidraw*", KERNELS=="*28DE:*", MODE="0666"

      '';
      destination = "/etc/udev/rules.d/99-steamcontroller.rules";
    };
  };

  services.udev.packages = [ pkgs.steamcontroller-udev-rules ];
  services.emacs = {
    defaultEditor = true;
    enable = true;
    install = true;
  };

  # ram verdoppler
  zramSwap.enable = false;

  programs.adb.enable = true;

  #environment.etc."qemu/bridge.conf".text = ''
  #  allow bridge0
  #'';

}

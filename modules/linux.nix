{
  pkgs,
  lib,
  llm-agents,
  ...
}:

let
  # A loopback sink for WirePlumber's role-based linking policy, see
  # services.pipewire below.
  roleSink =
    {
      name,
      desc,
      roles,
      priority,
      lowerPriorityAction,
      playbackProps ? { },
    }:
    {
      name = "libpipewire-module-loopback";
      args = {
        "node.name" = "loopback.sink.role.${name}";
        "node.description" = desc;
        # Positions per side, not in args: the module uses a top-level
        # audio.position as the format of both streams, so a playback
        # position set in playbackProps would only be a label.
        "capture.props" = {
          "media.class" = "Audio/Sink";
          "audio.position" = [
            "FL"
            "FR"
          ];
          # Keeps the sink out of GNOME's output list: libgvc skips portless
          # sinks on the bluetooth bus. WirePlumber only reads device.bus on
          # real devices. The "/Internal" media.class suffix used for rnnoise
          # would hide it too, but pulse clients then hang on drain.
          "device.bus" = "bluetooth";
          "device.intended-roles" = roles;
          "policy.role-based.target" = true;
          "policy.role-based.priority" = priority;
          "policy.role-based.action.same-priority" = "mix";
          # Applied by the higher-priority sink to the ones below it.
          "policy.role-based.action.lower-priority" = lowerPriorityAction;
        };
        "playback.props" = {
          "node.name" = "loopback.sink.role.${name}.output";
          "node.passive" = true;
          "audio.position" = [
            "FL"
            "FR"
          ];
        }
        // playbackProps;
      };
    };

  # Speech-triggered ducking for calls, see services.pipewire below. The
  # ducker is a 4-channel sink: media on FL/FR goes through a sidechain
  # compressor keyed by the call audio on RL/RR, which is mixed back in
  # unprocessed. Only standard positions work here: WirePlumber reshapes the
  # feeding streams to this layout, and AUX channels were silently dropped.
  voiceDucker = "input.voice-ducker";
  # Feeding the ducker: the streams must not upmix, or stereo media would
  # also land on RL/RR and duck itself.
  toVoiceDucker = positions: {
    "target.object" = voiceDucker;
    "audio.position" = positions;
    "channelmix.upmix" = false;
  };
in
{
  networking.extraHosts = ''
    192.168.98.3 wau
  '';
  networking.networkmanager.wifi.backend = "iwd";

  hardware.graphics.enable32Bit = true;
  hardware.graphics.enable = true;

  hardware.ksm.enable = true;

  console = {
    keyMap = "us";
  };

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "de_DE.UTF-8/UTF-8"
  ];

  hardware.sane.enable = true;
  hardware.sane.disabledDefaultBackends = [ "v4l" ];
  hardware.logitech.wireless.enable = true;

  boot.kernel.sysctl."kernel.dmesg_restrict" = 0;
  boot.loader.systemd-boot.memtest86.enable = true;
  boot.extraModprobeConfig = ''
    # exclusive_caps: Skype, Zoom, Teams etc. will only show device when actually streaming
    # card_label: Name of virtual camera, how it'll show up in Skype, Zoom, Teams
    # https://github.com/umlaeute/v4l2loopback
    options v4l2loopback exclusive_caps=1 card_label="Virtual Camera" video_nr=7
  '';

  fonts = {
    enableDefaultPackages = true;
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    fontconfig = {
      enable = true;
      allowBitmaps = true;
    };
    packages = with pkgs; [
      terminus_font
      terminus_font_ttf
      corefonts
      inconsolata
      ubuntu-classic
      unifont
      twemoji-color-font
      #nerd-fonts.source-code-pro
      nerd-fonts.fira-code
      nerd-fonts.droid-sans-mono
      nerd-fonts.dejavu-sans-mono
      #nerd-fonts.terminus
    ];
  };

  # fonts.fontDir (enabled above and by flatpak) bakes a font path into
  # xwayland, turning it into a variant Hydra never builds. Keep the stock
  # package so it comes from the binary cache.
  # Drop this if https://github.com/NixOS/nixpkgs/pull/552263 lands: it changes
  # the package default, which would make "" the uncached variant instead.
  programs.xwayland.defaultFontPath = "";

  # Role-based ducking: WirePlumber's role-based linking policy is on by
  # default but needs a loopback sink per role to act on. While a stream
  # plays into a sink, every lower-priority sink is ducked:
  #   40 Assistant (TTS, screen reader) = Communication (calls)
  #   20 Notification
  #   10 Multimedia (music, video, games; the default for role-less streams)
  # Calls are the exception: they keep their stream open even while nobody
  # talks, so link-based ducking would hold everything down for the whole
  # call. Communication therefore only mixes, and the voice ducker below
  # lowers media while someone actually speaks. TTS shares the level so a
  # call doesn't duck it; on a tie the most recent stream decides, so TTS
  # started during a call still ducks media and notifications.
  # pipewire-pulse maps the pulse roles (music, video, event, phone, ...)
  # onto these.
  services.pipewire = {
    enable = true;
    wireplumber.enable = true;
    pulse.enable = true;
    jack.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;

    extraLv2Packages = [ pkgs.lsp-plugins ];

    extraConfig.pipewire."90-role-ducking"."context.modules" = [
      (roleSink {
        name = "multimedia";
        desc = "Multimedia";
        roles = [
          "Music"
          "Movie"
          "Game"
          "Multimedia"
          "Production"
        ];
        priority = 10;
        lowerPriorityAction = "mix";
        playbackProps = toVoiceDucker [
          "FL"
          "FR"
        ];
      })
      (roleSink {
        name = "notification";
        desc = "Notification";
        roles = [ "Notification" ];
        priority = 20;
        lowerPriorityAction = "duck";
      })
      (roleSink {
        name = "assistant";
        desc = "Assistant";
        roles = [
          "Assistant"
          "Accessibility"
        ];
        priority = 40;
        lowerPriorityAction = "duck";
      })
      (roleSink {
        name = "communication";
        desc = "Communication";
        roles = [ "Communication" ];
        priority = 40;
        lowerPriorityAction = "mix";
        playbackProps = toVoiceDucker [
          "RL"
          "RR"
        ];
      })
    ];

    # If the ducker fails to load (nofail), both feeds fall back to the
    # default sink: everything still plays, just without call ducking.
    extraConfig.pipewire."91-voice-ducker"."context.modules" = [
      {
        name = "libpipewire-module-filter-chain";
        flags = [ "nofail" ];
        args = {
          "node.description" = "Voice Ducker";
          "media.name" = "Voice Ducker";
          "filter.graph" = {
            nodes = [
              {
                type = "lv2";
                name = "comp";
                plugin = "http://lsp-plug.in/plugins/lv2/sc_compressor_stereo";
                # External sidechain (sct = 2, the default). Threshold and
                # ratio by LV2 symbol: al ~ -40 dB, times in ms.
                control = {
                  al = 1.0e-2;
                  cr = 10.0;
                  at = 10.0;
                  hold = 500.0;
                  rt = 800.0;
                };
              }
              {
                type = "builtin";
                name = "voice_l";
                label = "copy";
              }
              {
                type = "builtin";
                name = "voice_r";
                label = "copy";
              }
              {
                type = "builtin";
                name = "mix_l";
                label = "mixer";
              }
              {
                type = "builtin";
                name = "mix_r";
                label = "mixer";
              }
            ];
            links = [
              {
                output = "voice_l:Out";
                input = "comp:sc_l";
              }
              {
                output = "voice_r:Out";
                input = "comp:sc_r";
              }
              {
                output = "comp:out_l";
                input = "mix_l:In 1";
              }
              {
                output = "comp:out_r";
                input = "mix_r:In 1";
              }
              {
                output = "voice_l:Out";
                input = "mix_l:In 2";
              }
              {
                output = "voice_r:Out";
                input = "mix_r:In 2";
              }
            ];
            inputs = [
              "comp:in_l"
              "comp:in_r"
              "voice_l:In"
              "voice_r:In"
            ];
            outputs = [
              "mix_l:Out"
              "mix_r:Out"
            ];
          };
          "capture.props" = {
            "node.name" = voiceDucker;
            "media.class" = "Audio/Sink";
            "device.bus" = "bluetooth"; # hidden from GNOME, see roleSink
            "audio.channels" = 4;
            "audio.position" = [
              "FL"
              "FR"
              "RL"
              "RR"
            ];
          };
          "playback.props" = {
            "node.name" = "output.voice-ducker";
            "node.passive" = true;
            # Any role that no role sink claims, so the output goes to the
            # default sink. Without one it would get the Multimedia default
            # and loop back into the Multimedia sink.
            "media.role" = "DSP";
            "audio.channels" = 2;
            "audio.position" = [
              "FL"
              "FR"
            ];
          };
        };
      }
    ];
    # Discord sets no media.role at all. Its voice engine (WebRTC's pulse
    # backend) plays calls through a stream named "playStream"; its other
    # sounds go through Chromium and stay in the Multimedia default.
    extraConfig.pipewire-pulse."90-discord-voice-role"."stream.rules" = [
      {
        matches = [
          {
            "application.process.binary" = "~.*[Dd]iscord.*";
            "media.name" = "playStream";
          }
        ];
        actions.update-props."media.role" = "Communication";
      }
    ];
    wireplumber.extraConfig."90-role-ducking"."wireplumber.settings" = {
      "node.stream.default-media-role" = "Multimedia";
      "linking.role-based.duck-level" = 0.3;
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.bara = {
    isNormalUser = true;
    uid = 1000;
    group = "bara";
    extraGroups = [
      "dialout"
      "scanner"
      "users"
      "video"
      "render"
      "wheel"
      "adm"
      "audio"
      "docker"
      "input"
      "vboxusers"
      "adbusers"
      "libvirtd"
      "plugdev"
      "networkmanager"
    ];
    createHome = true;
    shell = pkgs.zsh;
  };
  users.extraGroups.bara.gid = 1000;

  services.gvfs.enable = true;
  services.fwupd.enable = true;
  services.tzupdate.enable = true;
  services.earlyoom.enable = true;

  services = {
    flatpak.enable = true;
    resolved.settings.Resolve.FallbackDNS = [ "" ];
    openssh.enable = true;
    openssh.settings.X11Forwarding = true;
    udisks2.enable = true;
    printing.enable = true;
    printing.drivers = with pkgs; [
      gutenprint
      brlaser
      brgenml1lpr
      brgenml1cupswrapper
    ];
    displayManager = {
      autoLogin = {
        enable = false;
        user = "bara";
      };
      defaultSession = "gnome";
    };
    displayManager.gdm.enable = true;
    xserver.enable = true;

  };

  systemd.tmpfiles.rules = [
    # Use my monitor config
    "L+ /run/gdm/.config/monitors.xml - - - - /home/bara/.config/monitors.xml"
    # Exclude codebase-memory-mcp sockets
    "x /tmp/cbm-daemon-*"
  ];

  services.envfs.enable = true;
  services.envfs.extraFallbackPathCommands = ''
    ln -s ${pkgs.bash}/bin/bash $out/bash
    ln -s ${pkgs.coreutils}/bin/uname $out/uname
  '';

  security.rtkit.enable = true;
  services.smartd.enable = true;

  xdg.autostart.enable = true;
  xdg.portal = {
    xdgOpenUsePortal = true;
    enable = true;
  };

  # programs.immersed.enable = true;
  programs.firefox = {
    enable = true;
    languagePacks = [
      "en-US"
      "de"
    ];
  };
  programs.gnupg.agent = {
    enable = true;
  };
  services.pcscd.enable = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    icu
    icu75
    libX11
    libXext
    libgbm
    libusb1
    stdenv.cc.cc.lib
  ];

  # raise limit to avoid steamplay problems
  systemd.settings.Manager.DefaultLimitNOFILE = 1048576;
  programs.fuse.userAllowOther = true;

  virtualisation.spiceUSBRedirection.enable = true;

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  hardware.bluetooth.enable = true;
  hardware.usb-modeswitch.enable = true;

  programs.direnv = {
    enable = true;
    silent = false;
    loadInNixShell = true;
    direnvrcExtra = "";
    nix-direnv.enable = true;
  };

  programs.nix-index.enable = true;
  programs.nix-index.enableZshIntegration = true;
  programs.command-not-found.enable = false;
  programs.bash.completion.enable = true;
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };
  programs.zoxide.enable = true;

  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;

  environment.systemPackages = with pkgs; [
    alsa-utils
    #appimage-run
    aspell
    aspellDicts.de
    aspellDicts.en
    avahi
    binutils
    bitwarden-cli
    bitwarden-desktop
    blackbox-terminal
    cifs-utils
    dconf-editor
    espeak
    evince
    ghex
    ghostty
    gitg
    gitte
    gnome-boxes
    gnome-console
    gnome-tweaks
    gnome-usage
    google-chrome
    gsmartcontrol
    hdparm
    iotop
    keepassxc
    libnotify
    lm_sensors
    mtools
    (broken mumble "build failure")
    ntfs3g
    nvme-cli
    pamixer
    pavucontrol
    pciutils
    pdfarranger
    ptyxis
    qjackctl
    remmina
    smartmontools
    show-midi
    speechd
    spice-gtk
    sshfs-fuse
    usbutils
    virt-manager
    vlc
    # winboat
    wireguard-tools
    wl-clipboard

    (broken my-vscode "csharp extension")
    # The GNOME screen reader also installs bin/orca; leave that name to it,
    # the IDE's own entry point is orca-ide.
    (lib.lowPrio llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.orca)
  ];

  services.pipewire = {
    extraLadspaPackages = with pkgs; [ rnnoise-plugin ];
    extraConfig.pipewire."99-input-denoising.conf" = {
      "context.modules" = [
        {
          name = "libpipewire-module-filter-chain";
          args = {
            "node.description" = "Noise Canceling source";
            "media.name" = "Noise Canceling source";
            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  name = "rnnoise";
                  plugin = "librnnoise_ladspa";
                  label = "noise_suppressor_mono";
                  control = {
                    "VAD Threshold (%)" = 50.0;
                    "VAD Grace Period (ms)" = 200;
                    "Retroactive VAD Grace (ms)" = 0;
                  };
                }
              ];
            };
            "capture.props" = {
              "node.name" = "capture.rnnoise_source";
              # The "/Internal" suffix keeps both ends of the filter out of the
              # desktop's device and stream lists: pipewire-pulse matches
              # media.class exactly (pw_manager_object_is_source /
              # _is_source_output), while WirePlumber matches it as a substring
              # everywhere, so the filter is still linked normally.
              "media.class" = "Stream/Input/Audio/Internal";
              "node.passive" = true;
              "node.virtual" = true;
              "node.pause-on-idle" = true;
              "node.always-process" = false;
              "audio.rate" = 48000;
              "filter.smart" = true;
              "filter.smart.name" = "rnnoise-filter";
            };
            "playback.props" = {
              "node.name" = "rnnoise_source";
              # Must stay exactly "Audio/Source": this is the node pulse
              # clients see, and suffixing the equivalent node on the speaker
              # filter ("Audio/Sink/Internal") made pulse streams hang forever
              # on drain. Not worth risking capture to hide a list entry.
              "media.class" = "Audio/Source";
              "node.virtual" = true;
              "audio.rate" = 48000;
              "filter.smart" = true;
              "filter.smart.name" = "rnnoise-filter";
            };
          };
        }
      ];
    };
  };

}

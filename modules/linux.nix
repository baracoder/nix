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

  # Signal-based ducking, see services.pipewire below. The ducker is a
  # 6-channel sink with one stereo pair per source:
  #   FL/FR media, SL/SR games, RL/RR calls
  # Games go through a sidechain compressor keyed by media, the result plus
  # media through one keyed by calls; call audio is mixed back in unprocessed.
  # Only standard positions work here: WirePlumber reshapes the feeding
  # streams to this layout, and AUX channels were silently dropped.
  ducker = "input.ducker";
  # Feeding the ducker: the streams must not upmix, or stereo media would
  # also land on the other pairs and duck itself.
  toDucker = positions: {
    "target.object" = ducker;
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
  #   10 Multimedia (music, video; the default for role-less streams) = Game
  # Calls are the exception: they keep their stream open even while nobody
  # talks, so link-based ducking would hold everything down for the whole
  # call. Communication therefore only mixes, and the ducker below lowers
  # media and games while someone actually speaks. Games ducking behind
  # media is signal-based for the same reason: a paused browser tab may keep
  # its stream open. TTS shares the level so a
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
          "Multimedia"
          "Production"
        ];
        priority = 10;
        lowerPriorityAction = "mix";
        playbackProps = toDucker [
          "FL"
          "FR"
        ];
      })
      (roleSink {
        name = "game";
        desc = "Game";
        roles = [ "Game" ];
        priority = 10;
        lowerPriorityAction = "mix";
        playbackProps = toDucker [
          "SL"
          "SR"
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
        playbackProps = toDucker [
          "RL"
          "RR"
        ];
      })
    ];

    # If the ducker fails to load (nofail), all feeds fall back to the
    # default sink: everything still plays, just without signal ducking.
    # Controls can be tuned live, e.g. for the game stage:
    #   pw-cli set-param <input.ducker id> Props '{ params = [ "game_comp:cdr" 0.3 ] }'
    extraConfig.pipewire."91-ducker"."context.modules" =
      let
        # Shared by both stages: threshold al ~ -40 dB, times in ms. External
        # sidechain (sct = 2) is the default. cdr/cwt are a parallel mix of
        # the untouched (dry) and compressed (wet) signal: summing to 1 keeps
        # the level unchanged at rest, and the dry part is a floor, so fully
        # ducked the signal still plays at cdr (0.15 ~ -16 dB, 0.3 ~ -10 dB).
        compressor = name: control: {
          type = "lv2";
          inherit name;
          plugin = "http://lsp-plug.in/plugins/lv2/sc_compressor_stereo";
          control = {
            al = 1.0e-2;
            cr = 10.0;
            at = 10.0;
          }
          // control;
        };
        builtin = label: name: {
          type = "builtin";
          inherit name label;
        };
        link = output: input: { inherit output input; };
      in
      [
        {
          name = "libpipewire-module-filter-chain";
          flags = [ "nofail" ];
          args = {
            "node.description" = "Ducker";
            "media.name" = "Ducker";
            "filter.graph" = {
              nodes = [
                # Games behind media. Longer hold and release than for
                # speech so quiet passages and track changes don't pump.
                (compressor "game_comp" {
                  hold = 1000.0;
                  rt = 1500.0;
                  cdr = 0.2;
                  cwt = 0.8;
                })
                # Media and games behind calls.
                (compressor "voice_comp" {
                  hold = 500.0;
                  rt = 800.0;
                  cdr = 0.15;
                  cwt = 0.85;
                })
                # copy nodes fan a graph input out to several ports.
                (builtin "copy" "media_l")
                (builtin "copy" "media_r")
                (builtin "copy" "voice_l")
                (builtin "copy" "voice_r")
                (builtin "mixer" "sum_l")
                (builtin "mixer" "sum_r")
                (builtin "mixer" "mix_l")
                (builtin "mixer" "mix_r")
              ];
              links = [
                (link "media_l:Out" "game_comp:sc_l")
                (link "media_r:Out" "game_comp:sc_r")
                (link "game_comp:out_l" "sum_l:In 1")
                (link "game_comp:out_r" "sum_r:In 1")
                (link "media_l:Out" "sum_l:In 2")
                (link "media_r:Out" "sum_r:In 2")
                (link "sum_l:Out" "voice_comp:in_l")
                (link "sum_r:Out" "voice_comp:in_r")
                (link "voice_l:Out" "voice_comp:sc_l")
                (link "voice_r:Out" "voice_comp:sc_r")
                (link "voice_comp:out_l" "mix_l:In 1")
                (link "voice_comp:out_r" "mix_r:In 1")
                (link "voice_l:Out" "mix_l:In 2")
                (link "voice_r:Out" "mix_r:In 2")
              ];
              # In the order of audio.position below.
              inputs = [
                "media_l:In"
                "media_r:In"
                "game_comp:in_l"
                "game_comp:in_r"
                "voice_l:In"
                "voice_r:In"
              ];
              outputs = [
                "mix_l:Out"
                "mix_r:Out"
              ];
            };
            "capture.props" = {
              "node.name" = ducker;
              "media.class" = "Audio/Sink";
              "device.bus" = "bluetooth"; # hidden from GNOME, see roleSink
              "audio.channels" = 6;
              "audio.position" = [
                "FL"
                "FR"
                "SL"
                "SR"
                "RL"
                "RR"
              ];
            };
            "playback.props" = {
              "node.name" = "output.ducker";
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
    # Wine sets no media.role either. Under Wine/Proton that's nearly always a
    # game; native SDL games already set Game themselves.
    extraConfig.pipewire-pulse."90-wine-game-role"."stream.rules" = [
      {
        matches = [ { "application.process.binary" = "~^wine(64)?(-preloader)?$"; } ];
        actions.update-props."media.role" = "Game";
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
    vulnix
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

{
  pkgs,
  lib,
  ...
}:
let
  # Internal Conexant SN6140 analog codec. The built-in speakers and the 3.5mm
  # jack are two routes on this single sink, so the DSP has to be bypassed at
  # runtime when headphones are plugged in.
  internalSink = "alsa_output.pci-0000_c4_00.6.analog-stereo";
  alsaCard = "Generic_1";

  # The node carrying the filter graph, and hence its controls.
  dspNode = "effect_input.speaker-dsp";

  # Speaker correction IR, exported from the EasyEffects convolver preset.
  # Must be tracked by git or the flake build won't see it.
  impulseResponse = ./IR_100ms_28dB_5t_15s_0c.wav;

  # Bypass works by crossfading the mixer at the end of the graph between the
  # processed chain (In 1) and the untouched dry signal (In 2). The convolver
  # has no bypass control of its own, and neither PipeWire's
  # `audioconvert.filter-graph.disable` nor WirePlumber's
  # `filter.smart.disabled` metadata takes effect on an already-running graph.
  speaker-dsp-bypass = pkgs.writeShellApplication {
    name = "speaker-dsp-bypass";
    runtimeInputs = with pkgs; [
      pipewire
      jq
    ];
    text = ''
      # usage: speaker-dsp-bypass on|off   (on = bypassed, off = processed)
      case "''${1:-}" in
        on)  wet=0.0; dry=1.0 ;;
        off) wet=1.0; dry=0.0 ;;
        *)   echo "usage: speaker-dsp-bypass on|off" >&2; exit 2 ;;
      esac
      id=$(pw-dump | jq -r --arg n "${dspNode}" \
        'first(.[] | select(.info.props."node.name" == $n) | .id) // empty')
      if [ -z "$id" ]; then
        echo "filter node ${dspNode} not found" >&2
        exit 1
      fi
      pw-cli set-param "$id" Props \
        "{ params = [ \"mix_l:Gain 1\" $wet \"mix_l:Gain 2\" $dry \"mix_r:Gain 1\" $wet \"mix_r:Gain 2\" $dry ] }" \
        >/dev/null
    '';
  };

  speaker-dsp-jack-watch = pkgs.writeShellApplication {
    name = "speaker-dsp-jack-watch";
    runtimeInputs = with pkgs; [
      alsa-utils
      speaker-dsp-bypass
    ];
    text = ''
      apply() {
        if amixer -c ${alsaCard} cget iface=CARD,name='Headphone Jack' | grep -q 'values=on'; then
          speaker-dsp-bypass on
        else
          speaker-dsp-bypass off
        fi
      }

      # PipeWire may not have created the filter node yet when we start.
      for _ in $(seq 30); do
        if apply; then break; fi
        sleep 1
      done

      # alsactl wants a CTL device name here, not a card name like amixer -c.
      alsactl monitor hw:${alsaCard} | while read -r _; do
        apply || true
      done
    '';
  };
in
{
  services.pipewire.extraLv2Packages = [ pkgs.lsp-plugins ];

  # Speaker correction for the built-in speakers, ported from the EasyEffects
  # "Speakers" preset. Only the convolver and the limiter were active there;
  # bass_enhancer, filter, multiband_compressor and loudness were all bypassed.
  #
  # Registered as a smart filter targeting the internal sink, so WirePlumber
  # inserts it only for streams routed there and leaves HDMI/Bluetooth/USB
  # untouched. (Attaching the graph to the ALSA node directly via
  # `node.param.Props` does not work: WirePlumber sets node properties after
  # pw_impl_node_set_implementation, which is the only place `node.param.*` is
  # consumed, so the graph is silently never loaded.)
  services.pipewire.extraConfig.pipewire."99-speaker-dsp.conf" = {
    "context.modules" = [
      {
        name = "libpipewire-module-filter-chain";
        args = {
          "node.description" = "Speaker DSP";
          "media.name" = "Speaker DSP";
          "filter.graph" = {
            nodes = [
              # copy nodes exist purely to fan the input out to both the
              # processed chain and the dry path of the bypass mixer; a graph
              # input can only be mapped to one port.
              {
                type = "builtin";
                name = "copy_l";
                label = "copy";
              }
              {
                type = "builtin";
                name = "copy_r";
                label = "copy";
              }
              # The IR is stereo, so one convolver instance per channel.
              {
                type = "builtin";
                name = "conv_l";
                label = "convolver";
                config = {
                  filename = "${impulseResponse}";
                  channel = 0;
                };
              }
              {
                type = "builtin";
                name = "conv_r";
                label = "convolver";
                config = {
                  filename = "${impulseResponse}";
                  channel = 1;
                };
              }
              # EasyEffects' limiter is this plugin; values map 1:1 from the
              # preset (gains are linear, so 0 dB = 1.0).
              {
                type = "lv2";
                name = "limiter";
                plugin = "http://lsp-plug.in/plugins/lv2/limiter_stereo";
                control = {
                  mode = 0; # Herm Thin
                  th = 1.0; # threshold 0 dB
                  at = 5.0; # attack ms
                  rt = 5.0; # release ms
                  lk = 5.0; # lookahead ms
                  boost = 1; # gain boost
                  alr = 0; # automatic level regulation off
                  ovs = 0; # no oversampling
                  dith = 0; # no dithering
                  slink = 100.0; # stereo link %
                };
              }
              {
                type = "builtin";
                name = "mix_l";
                label = "mixer";
                control = {
                  "Gain 1" = 1.0;
                  "Gain 2" = 0.0;
                };
              }
              {
                type = "builtin";
                name = "mix_r";
                label = "mixer";
                control = {
                  "Gain 1" = 1.0;
                  "Gain 2" = 0.0;
                };
              }
            ];
            links = [
              {
                output = "copy_l:Out";
                input = "conv_l:In";
              }
              {
                output = "copy_r:Out";
                input = "conv_r:In";
              }
              {
                output = "conv_l:Out";
                input = "limiter:in_l";
              }
              {
                output = "conv_r:Out";
                input = "limiter:in_r";
              }
              {
                output = "limiter:out_l";
                input = "mix_l:In 1";
              }
              {
                output = "limiter:out_r";
                input = "mix_r:In 1";
              }
              {
                output = "copy_l:Out";
                input = "mix_l:In 2";
              }
              {
                output = "copy_r:Out";
                input = "mix_r:In 2";
              }
            ];
            inputs = [
              "copy_l:In"
              "copy_r:In"
            ];
            outputs = [
              "mix_l:Out"
              "mix_r:Out"
            ];
          };
          "audio.channels" = 2;
          "audio.position" = [
            "FL"
            "FR"
          ];
          "capture.props" = {
            "node.name" = dspNode;
            # "Audio/Sink/Internal" rather than "Audio/Sink" keeps the filter
            # out of the desktop's output list: pipewire-pulse only exposes an
            # exact "Audio/Sink" (pw_manager_object_is_sink), while WirePlumber
            # matches the class as a substring everywhere, so the node is still
            # treated as an input-direction filter and linked normally. Same
            # convention WirePlumber itself uses for hidden nodes in
            # monitors/alsa.lua and monitors/bluez.lua.
            "media.class" = "Audio/Sink/Internal";
            "audio.position" = [
              "FL"
              "FR"
            ];
            "filter.smart" = true;
            "filter.smart.name" = "speaker-dsp";
            "filter.smart.target" = {
              "node.name" = internalSink;
            };
          };
          "playback.props" = {
            "node.name" = "effect_output.speaker-dsp";
            # Likewise keeps the filter's output out of pavucontrol's playback
            # tab; pw_manager_object_is_sink_input also matches exactly.
            "media.class" = "Stream/Output/Audio/Internal";
            "node.passive" = true;
            "audio.position" = [
              "FL"
              "FR"
            ];
          };
        };
      }
    ];
  };

  systemd.user.services.speaker-dsp-jack-watch = {
    description = "Bypass speaker DSP while headphones are plugged in";
    wantedBy = [ "pipewire.service" ];
    after = [ "pipewire.service" ];
    bindsTo = [ "pipewire.service" ];
    # Without this a burst of restarts trips the rate limit and leaves the
    # service dead until manually reset.
    unitConfig.StartLimitIntervalSec = 0;
    serviceConfig = {
      ExecStart = lib.getExe speaker-dsp-jack-watch;
      Restart = "always";
      RestartSec = 2;
    };
  };

  environment.systemPackages = [ speaker-dsp-bypass ];
}

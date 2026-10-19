{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hal.crashDiagnostics;

  # Runtime switch for the deepest CPU idle state, so the test can be flipped
  # without a rebuild: `hal-c3 off` disables C3, `hal-c3 on` restores it.
  hal-c3 = pkgs.writeShellApplication {
    name = "hal-c3";
    text = ''
      case "''${1:-}" in
        on) v=0 ;;
        off) v=1 ;;
        status)
          grep -H . /sys/devices/system/cpu/cpu*/cpuidle/state3/disable | sort -V
          exit 0
          ;;
        *)
          echo "usage: hal-c3 on|off|status" >&2
          exit 1
          ;;
      esac
      for f in /sys/devices/system/cpu/cpu*/cpuidle/state3/disable; do
        echo "$v" > "$f"
      done
      echo "C3 $1 ($(cat /sys/devices/system/cpu/cpu0/cpuidle/state3/name))"
    '';
  };
in
{
  # hal resets spontaneously during light use, roughly once every 1-3 weeks,
  # and the next boot reports
  #
  #   x86/amd: Previous system reset reason [0x00800800]: internal CPU shutdown event occurred
  #
  # The kernel never gets to log anything (kernel.panic=0, so a panic would
  # hang rather than reboot), and the firmware has no BERT/HEST, so nothing
  # survives. This module collects what can be collected from the OS side.
  # See firmware-analysis/README.md for the investigation.

  options.hal.crashDiagnostics = {
    disableC3 = lib.mkEnableOption ''
      disabling the C3 (CC6) idle state at boot. The resets only happen under
      light load, where cores enter C3 millions of times. If they stop with
      this set, the idle-state transitions are implicated. Costs some idle
      power and heat'';
  };

  config = {
    # journald fsyncs every 5 min by default, so a hard reset can lose up to
    # the last 5 minutes of logs, exactly the part that matters here.
    services.journald.settings.Journal.SyncIntervalSec = "5s";

    # Records machine checks, PCIe AER and memory errors to a database
    # (`ras-mc-ctl --summary` / `--errors`). Corrected errors in the run-up
    # to a reset would point at failing hardware or a marginal voltage.
    hardware.rasdaemon.enable = true;

    # Report MCA bank contents left over from before the reset, in case the
    # firmware does not clear them. Believed to be the default on Zen
    # already; set explicitly so it doesn't depend on the kernel's quirks.
    boot.kernelParams = [ "mce=bootlog" ];

    # A snapshot line every 2 s (~4 MB of journal per day), so the last
    # seconds before a reset are on disk:
    #   journalctl -b -1 -u hal-crash-logger | tail
    systemd.services.hal-crash-logger = {
      description = "Log platform state for post-mortem of spontaneous resets";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.python3}/bin/python3 -I ${./crash-logger.py} 2";
        Restart = "always";
        RestartSec = 5;
        Nice = 10;
      };
    };

    systemd.services.hal-disable-c3 = lib.mkIf cfg.disableC3 {
      description = "Disable the C3 idle state (reset investigation)";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${hal-c3}/bin/hal-c3 off";
        ExecStop = "${hal-c3}/bin/hal-c3 on";
      };
    };

    environment.systemPackages = [ hal-c3 ];
  };
}

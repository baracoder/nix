{
  writeShellApplication,
  systemd,
  gnused,
  coreutils,
}:

# Small CLI around the PowerStation D-Bus interface, mirroring what `hhdctl set
# tdp.qam.tdp=N` used to do. The card object path is discovered at runtime
# because it is named after the DRM card.
writeShellApplication {
  name = "powerstation-tdp";
  runtimeInputs = [
    systemd
    gnused
    coreutils
  ];
  text = ''
    bus_name=org.shadowblip.PowerStation
    gpu_path=/org/shadowblip/Performance/GPU
    tdp_iface=org.shadowblip.GPU.Card.TDP

    usage() {
      cat <<'USAGE'
    Usage: powerstation-tdp <command> [args]

      get             print the current TDP in watts
      set <watts>     set the TDP
      boost [watts]   print the boost, or set it; 0 disables it
      range           print the reported "<min> <max>" TDP limits
      path            print the D-Bus object path of the controllable card
      wait [seconds]  block until PowerStation exposes a controllable card
    USAGE
    }

    # Prints the object path of the first card that implements the TDP interface.
    card_path() {
      local cards candidate
      cards=$(busctl --system call "$bus_name" "$gpu_path" \
        org.shadowblip.GPU EnumerateCards) || return 1
      # Reply looks like: ao 1 "/org/shadowblip/Performance/GPU/card0"
      cards=$(printf '%s\n' "$cards" | sed -e 's/^ao [0-9]* //' -e 's/"//g')
      local xml
      for candidate in $cards; do
        # Captured rather than piped into grep: pipefail plus an early-exiting
        # reader would turn a match into a SIGPIPE failure.
        xml=$(busctl --system call "$bus_name" "$candidate" \
          org.freedesktop.DBus.Introspectable Introspect 2>/dev/null) || continue
        case "$xml" in
          *"$tdp_iface"*)
            printf '%s\n' "$candidate"
            return 0
            ;;
        esac
      done
      return 1
    }

    # Sets $card, or bails out with something more useful than the "invalid
    # object path" busctl reports when handed an empty path.
    resolve_card() {
      if ! card=$(card_path); then
        echo "powerstation-tdp: PowerStation exposes no card with TDP control" >&2
        echo "  check: systemctl status powerstation; journalctl -u powerstation" >&2
        exit 1
      fi
    }

    # busctl prints properties as "<signature> <value>"; we only want the value.
    get_property() {
      busctl --system get-property "$bus_name" "$card" "$tdp_iface" "$1" |
        cut -d' ' -f2-
    }

    cmd=''${1:-}
    case "$cmd" in
      get)
        resolve_card
        get_property TDP
        ;;
      set)
        watts=''${2:-}
        if [ -z "$watts" ]; then
          echo "powerstation-tdp: set requires a value in watts" >&2
          exit 1
        fi
        resolve_card
        busctl --system set-property "$bus_name" "$card" \
          "$tdp_iface" TDP d "$watts"
        ;;
      boost)
        # PowerStation's boost is the headroom above the sustained limit: it
        # sets the slow PPT to TDP + boost and the fast PPT to 1.25x that.
        # This is hhd's "Boost" checkbox; 0 is unchecked.
        resolve_card
        watts=''${2:-}
        if [ -z "$watts" ]; then
          get_property Boost
        else
          busctl --system set-property "$bus_name" "$card" \
            "$tdp_iface" Boost d "$watts"
        fi
        ;;
      range)
        resolve_card
        echo "$(get_property MinTdp) $(get_property MaxTdp)"
        ;;
      path)
        resolve_card
        printf '%s\n' "$card"
        ;;
      wait)
        deadline=$(( $(date +%s) + ''${2:-60} ))
        until card_path >/dev/null 2>&1; do
          if [ "$(date +%s)" -ge "$deadline" ]; then
            echo "powerstation-tdp: timed out waiting for PowerStation" >&2
            exit 1
          fi
          sleep 1
        done
        ;;
      -h | --help | help | "")
        usage
        ;;
      *)
        echo "powerstation-tdp: unknown command '$cmd'" >&2
        usage >&2
        exit 1
        ;;
    esac
  '';
}

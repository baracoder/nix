{
  ...
}:
let
  # The internal touchpad, an I2C-HID device on the AMDI0010:00 bus.
  # (GXTP7385:00 on i2c-1 is the Goodix touchscreen -- a different device.)
  client = "i2c-PNP0C50:00";
  driver = "i2c_hid_acpi";
in
{
  # The touchpad intermittently fails to come up at boot. The kernel reads a
  # garbage HID descriptor and aborts the probe:
  #
  #   i2c_hid_acpi i2c-PNP0C50:00: weird size of HID descriptor (261)
  #   i2c_hid_acpi i2c-PNP0C50:00: Failed to fetch the HID Descriptor
  #
  # The i2c client still exists afterwards, it just has no driver bound, and a
  # manual rebind brings the touchpad straight back without a reboot. So this
  # is a one-shot bad read on a cold bus (the touchpad MCU being slow out of
  # reset), not a driver or config problem -- it hit 1 of the last 15 boots on
  # an otherwise unchanged kernel.
  #
  # There is no quirk to set instead: i2c-hid hard-rejects any descriptor whose
  # size isn't the spec's 30 bytes, with no override.
  systemd.services.touchpad-rebind = {
    description = "Rebind the touchpad if its I2C-HID probe failed at boot";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      dev=/sys/bus/i2c/devices/${client}
      bind=/sys/bus/i2c/drivers/${driver}/bind

      # The i2c client is created by the ACPI enumeration, independently of
      # whether the HID probe then succeeds, so waiting for it distinguishes
      # "not there yet" from "there but unbound".
      for _ in $(seq 30); do
        [ -e "$dev" ] && break
        sleep 1
      done
      if [ ! -e "$dev" ]; then
        echo "$dev never appeared; touchpad missing from the i2c bus entirely" >&2
        exit 0
      fi

      # A driver symlink means the probe succeeded and there is nothing to do,
      # which is the common case.
      if [ -e "$dev/driver" ]; then
        exit 0
      fi

      # Retry rather than bind once: the failure is a timing one, so each
      # further second of settle time improves the odds of a clean read.
      for attempt in 1 2 3; do
        echo "${client} unbound, rebind attempt $attempt"
        echo '${client}' > "$bind" 2>/dev/null || true
        if [ -e "$dev/driver" ]; then
          echo "touchpad rebound successfully"
          exit 0
        fi
        sleep 2
      done

      # Non-fatal: a dead touchpad should not make the boot look failed.
      echo "could not rebind ${client}; a full power-off may be needed" >&2
    '';
  };
}

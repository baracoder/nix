#!/usr/bin/env bash

DEVICE_PREFIXES=(0018:0911:5288 0018:27C6:0113)
DRIVER_DIR="/sys/bus/hid/drivers/hid-multitouch"
HID_DEVICES_DIR="/sys/bus/hid/devices"

# Find the current full device ID for a given prefix (instance part may change)
find_bound_device() {
    local prefix="$1"
    basename "$(ls -d "$DRIVER_DIR/${prefix}."* 2>/dev/null | head -1)" 2>/dev/null
}

find_any_device() {
    local prefix="$1"
    basename "$(ls -d "$HID_DEVICES_DIR/${prefix}."* 2>/dev/null | head -1)" 2>/dev/null
}

dbus-monitor --system "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path='/org/freedesktop/login1'" |
while read -r _; do
    # Check if the LidClosed property just changed
    LID_STATE=$(busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager LidClosed | awk '{print $2}')

    if [ "$LID_STATE" == "true" ]; then
        for prefix in "${DEVICE_PREFIXES[@]}"; do
            dev=$(find_bound_device "$prefix")
            if [ -n "$dev" ]; then
                echo "$dev" > "$DRIVER_DIR/unbind"
            fi
        done
    else
        for prefix in "${DEVICE_PREFIXES[@]}"; do
            dev=$(find_any_device "$prefix")
            if [ -n "$dev" ] && [ ! -e "$DRIVER_DIR/$dev" ]; then
                echo "$dev" > "$DRIVER_DIR/bind" 2>/dev/null
            fi
        done
    fi
done


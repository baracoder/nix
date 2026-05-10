#!/usr/bin/env bash

DEVICES=("0018:0911:5288.0005" "0018:27C6:0113.0004")
DRIVER_DIR="/sys/bus/hid/drivers/hid-multitouch"

# Detect lid state
LID_STATE=$(cat /proc/acpi/button/lid/*/state | awk '{print $NF}')


dbus-monitor --system "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path='/org/freedesktop/login1'" |
while read -r _; do
    # Check if the LidClosed property just changed
    LID_STATE=$(busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager LidClosed | awk '{print $2}')

    if [ "$LID_STATE" == "true" ]; then
        for dev in "${DEVICES[@]}"; do
            if [ -e "$DRIVER_DIR/$dev" ]; then
                echo "$dev" > "$DRIVER_DIR/unbind"
            fi
        done
    else
        for dev in "${DEVICES[@]}"; do
            if [ ! -e "$DRIVER_DIR/$dev" ]; then
                echo "$dev" > "$DRIVER_DIR/bind" 2>/dev/null
            fi
        done
    fi
done


"""Log a one-line platform snapshot every few seconds.

The hal resets ("internal CPU shutdown event") never reach the kernel, so the
journal just stops. Combined with a short journald SyncIntervalSec this
leaves a record of what the machine was doing in its last seconds: temperature,
package power, clocks, C-state activity, GPU load and battery/AC state.
"""

import glob
import os
import sys
import time

INTERVAL = float(sys.argv[1]) if len(sys.argv) > 1 else 2.0


def read(path, default=None):
    try:
        with open(path) as f:
            return f.read().strip()
    except OSError:
        return default


def hwmon(name):
    for d in glob.glob("/sys/class/hwmon/hwmon*"):
        if read(f"{d}/name") == name:
            return d
    return None


K10 = hwmon("k10temp")
RAPL = "/sys/class/powercap/intel-rapl:0/energy_uj"
CPUS = sorted(glob.glob("/sys/devices/system/cpu/cpu[0-9]*"))
STATES = sorted({os.path.basename(p) for p in glob.glob(f"{CPUS[0]}/cpuidle/state*")})
STATE_NAMES = [read(f"{CPUS[0]}/cpuidle/{s}/name", s) for s in STATES]
GPU_BUSY = (glob.glob("/sys/class/drm/card*/device/gpu_busy_percent") or [None])[0]


def idle_counters():
    """Per state: (entries, residency_us) summed over online CPUs."""
    out = []
    for s in STATES:
        usage = time_us = 0
        for c in CPUS:
            usage += int(read(f"{c}/cpuidle/{s}/usage", 0))
            time_us += int(read(f"{c}/cpuidle/{s}/time", 0))
        out.append((usage, time_us))
    return out


def snapshot():
    freqs = [int(read(f"{c}/cpufreq/scaling_cur_freq", 0)) for c in CPUS]
    freqs = [f for f in freqs if f]
    return {
        "t": time.monotonic(),
        "energy": int(read(RAPL, 0)),
        "idle": idle_counters(),
        "freq_avg": sum(freqs) // max(len(freqs), 1) // 1000,
        "freq_max": max(freqs, default=0) // 1000,
    }


def fmt(prev, cur):
    dt = cur["t"] - prev["t"]
    parts = []
    if K10:
        parts.append(f"tctl={int(read(f'{K10}/temp1_input', 0)) / 1000:.1f}C")
    de = cur["energy"] - prev["energy"]
    if de >= 0 and cur["energy"]:
        parts.append(f"pkg={de / 1e6 / dt:.1f}W")
    parts.append(f"mhz={cur['freq_avg']}/{cur['freq_max']}")
    ncpu = len(CPUS)
    for name, (pu, pt), (cu, ct) in zip(STATE_NAMES, prev["idle"], cur["idle"]):
        if name == "POLL":
            continue
        rate = (cu - pu) / dt
        res = (ct - pt) / (dt * 1e6 * ncpu) * 100
        parts.append(f"{name}={rate:.0f}/s,{res:.0f}%")
    if GPU_BUSY:
        parts.append(f"gpu={read(GPU_BUSY, '?')}%")
    parts.append(f"ac={read('/sys/class/power_supply/ADP1/online', '?')}")
    bat = "/sys/class/power_supply/BAT0"
    cur_ua = int(read(f"{bat}/current_now", 0))
    volt_uv = int(read(f"{bat}/voltage_now", 0))
    parts.append(
        f"bat={read(f'{bat}/status', '?')},{read(f'{bat}/capacity', '?')}%,"
        f"{cur_ua * volt_uv / 1e12:.1f}W"
    )
    parts.append(f"load={read('/proc/loadavg', '?').split()[0]}")
    return " ".join(parts)


def main():
    prev = snapshot()
    while True:
        time.sleep(INTERVAL)
        cur = snapshot()
        print(fmt(prev, cur), flush=True)
        prev = cur


if __name__ == "__main__":
    main()

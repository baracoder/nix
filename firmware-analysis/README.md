# GPD Win Max 2 (2025, Ryzen AI 9 HX 370) firmware analysis

Workspace for picking apart the vendor BIOS (AMI Aptio V + AMD AGESA
"StrixKrackan PI") to look for causes of spontaneous resets in low-power/idle
states. GPD ships no fixes beyond V0.21, so the goal is to understand what the
firmware does and work around it from the OS side (DSDT/SSDT overrides like
`machines/hal/dsdt`, kernel params, BIOS setup values).

Vendor binaries are proprietary and large: `archives/` and `work/` are
git-ignored. Only the tooling lives in git.

## Setup

```sh
nix develop .#firmware          # from the repo root; puts scripts/ on PATH
import-vendor --unpack          # archives/*.zip -> work/v0.18 v0.19 v0.21, work/ec
dump-live                       # sudo: live ACPI/SMBIOS/dmesg -> work/live-v<ver>
diff-versions work/v0.19 work/v0.21
```

The download is `archives/WIN-MAX-2-2025-20250811T070338Z-1-001.zip`, from
GPD's Google Drive. It holds three BIOS releases plus the EC image:

| BIOS  | Date       | Notes (from `Release_Note.txt`)                        |
|-------|------------|--------------------------------------------------------|
| 0.18  | 2025-01-06 | PI 1.1.0.0, OCuLink eGPU cold boot fix                 |
| 0.19  | 2025-02-11 | PI 1.1.0.0a, Micron 16G 8000 SPD                       |
| 0.21  | 2025-07-15 | Micron 8G 8000 SPD (**installed on hal**)              |
| EC 0.10 | 2024-11-29 | `work/ec/AHN28S_EC_V00.10.bin`, unchanged since 0.16 |

## What `unpack-rom` produces (per `work/v*/`)

| Path                  | Contents                                                          |
|-----------------------|-------------------------------------------------------------------|
| `bios.rom.dump/`      | UEFIExtract tree, every volume/file/section, decompressed         |
| `bios.rom.report.txt` | flat listing of the above                                         |
| `modules.tsv`         | UI name, GUID, type, size, CRC32 per FFS file                     |
| `psp.txt`/`psp.json`  | AMD PSP directories: PSP OS, ABL, SMU/PMFW, microcode, MP2, ...   |
| `psp-entries.tsv`     | flat unique PSP entries (type, version, size, md5)                |
| `psp/`                | extracted + uncompressed PSP blobs                                |
| `acpi/`               | DSDT + 69 SSDTs carved from the DXE drivers, `.aml` + `.dsl`, `index.tsv` maps each to its module |
| `setup/`              | IFR dumps of `Setup`, `AmdPbsSetupDxe`, `CbsSetupDxeSTX` (AMD CBS), incl. hidden options with their VarStore offsets |

Notes:
- The ROM only carries DSDT/SSDTs as static blobs; FACP/APIC/IVRS/PCCT etc.
  are generated at boot, so use `dump-live` for those. AMI also patches
  `Name()` placeholders (TPM, NVS addresses) at boot, so ROM vs live DSDTs
  differ in those lines.
- `diff-versions` compares module **sizes**, not CRCs. Every module's CRC
  changes per build because of embedded timestamps.
- PSPTool predates Strix Point and prints "Unknown zen_generation_id" and
  sha384 warnings (in `psp.warnings.txt`). Entry parsing and versions are fine.
- `machines/hal/dsdt/dsdt.dsl` is derived from the **v0.21** DSDT. The only
  semantic change is `LID0._STA` always returning `0x0F`. Re-derive it if the
  BIOS is ever changed.

## Tools in the shell

`uefiextract`/`uefifind`/`uefitool`, `uefi-firmware-parser`, `ifrextractor`,
`psptool` (packaged in `pkgs/psptool`), `amd-s2idle`/`amd-bios`/`amd-pstate`
(amd-debug-tools), `iasl`/`acpidump`/`acpixtract`, `fwts`, `ghidra` (with
ghidra-firmware-utils for FV/PE/TE loading), `rizin`, `binwalk`, `imhex`,
`vbindiff`, `dmidecode`, `unar`/`7zz`.

Ghidra: import a module's `PE32 image section/body.bin` from `bios.rom.dump/`
as PE, x86:LE:64. SMM modules (`AmdCpmOemSmm`, `AcpiModeEnable`, `FchSmm*`)
and `AmdCpmModernStandby*` are where idle/sleep behaviour lives.

## Findings / leads so far

- Symptom: random resets during light desktop use (browsing, music), sometimes
  minutes after boot, sometimes days apart. Not in s2idle. Lowering memory
  speed and disabling power saving did not help.
- **The kernel records the hardware reset reason** (`x86/amd: Previous system
  reset reason`). From 2026-09-15 to 2026-10-18 (36 boots): 17× `0xCF9`
  reboot, 16× `ACPI power state transition`, and **3× `0x00800800 internal
  CPU shutdown event`**: 2026-10-11 12:51 (the previous boot had been up
  **4 min**), 2026-10-11 21:14, and 2026-10-17 15:13. Each time the journal
  just stops, with no panic. `kernel.panic=0`, so a kernel panic would freeze
  the machine rather than reboot it; the reset bypassed the kernel. "Internal
  CPU shutdown" means a core entered the x86 shutdown state: a triple fault
  (in the kernel, or in SMM firmware code the OS cannot see), or a machine
  check that could not be delivered.
  `journalctl _TRANSPORT=kernel -g "reset reason"` lists them.
- **After a crash shortly after boot (undocked), the machine gets stuck**:
  powering it back on right away gives no display, and it only boots
  normally after being fully off for ~10 s. So the crash leaves some
  platform state behind that a reset doesn't clear, only a power-rail
  drain does: the EC, the USB-PD controller, the SMU/PSP firmware, or a
  latched voltage-regulator fault. That points below the OS. If it happens
  again, note the power LED, fan, keyboard backlight and whether Caps Lock
  toggles while stuck, then compare the reset reason the next boot reports.
- **No MCE record in any of 53 journaled boots.** MCA banks normally survive a
  warm reset and are reported on the next boot, unless AGESA clears them.
- CBS watchdogs (`AmdSetup` varstore 0x5000, offsets 0x45–0x49) are all on
  **Auto** in NVRAM. The effective state is in `MSR 0xC0010074`
  (`sudo rdmsr -a -x 0xc0010074`, bit 0 = enabled). On v0.21 every CPU
  reads `0x4289`: enabled, timebase 1.31 ms, count-select 1 (2047 ticks =
  **~2.68 s**, which matches the setup's "2.681s" option value `0x100`).
  Bits [9:7] = 5, which is most likely the severity field set to "Fatal"
  (this follows the setup's 0–5 encoding; I haven't confirmed it from the
  AGESA code). This is AMD's normal default. It fires only if a core makes
  no progress for ~2.7 s, so it would be reporting a hang, not causing one.
- The crashes happen under light load or shortly after login, never while
  gaming or compiling. Under light load cores enter C3 (CC6, 350 µs exit
  latency) millions of times. That makes idle-state or V/F transitions the
  first thing to test:
  `hal-c3 off` (runtime) or `hal.crashDiagnostics.disableC3 = true` in
  `machines/hal/default.nix`. Diagnostics collected by
  `machines/hal/crash-diagnostics.nix`: `journalctl -b -1 -u hal-crash-logger`,
  `ras-mc-ctl --errors`, and the reset reason / MCE bootlog in `journalctl -k`.
- **No APEI tables** (no BERT/HEST/EINJ in ROM or live). The firmware does not
  preserve error records across a fatal reset, so the OS never sees why it
  died. A persistent MCE log needs other means, e.g. `pstore`/`ramoops`, or
  netconsole to another box.
- Live SMU firmware 93.13.0 (`0x5D.0x0D`) matches the v0.21 ROM. CPU
  microcode is already updated by the kernel (`0xb204037`, ROM has
  `0xb204032`).
- Places to look next for idle-state issues:
  - `acpi/SSDT-UPEP-*` (uPEP/LPS0 `_DSM`, the Modern Standby constraints list)
    and `SSDT-CPMMSOSC`, `SSDT-GpMsSsdt`, `SSDT-CPMMSLPI`/`MSLPIDIS`.
  - `setup/CbsSetupDxeSTX*.ifr.txt`: AMD CBS knobs `Global C-state Control`,
    `DF Cstates`, `PSS Support`, `Power Down Enable`, and **`Core Watchdog
    Timer Enable/Interval/Severity`** + `DF Watchdog Timer Interval`. The
    core watchdog is a hang detector, not something software has to keep
    resetting: it fires when a core cannot complete an instruction or
    transaction, and it reports through MCA. A firing would normally leave an
    MCE record and/or a "sync flood" reset reason, which we don't see. So it
    is unlikely to be the cause, though not ruled out. Hidden options can
    still be changed through their VarStore offsets (e.g. `setup_var`-style
    tools from a UEFI shell).
  - SMM handlers (`*Smm` modules in `bios.rom.dump/`). They run on every SMI
    during normal use, invisible to the OS. A fault inside SMM would produce
    exactly a silent triple-fault reset.
  - `amd-s2idle test` and `amd-bios trace` on the live system; `fwts` for
    general ACPI sanity (`sudo fwts -b`).

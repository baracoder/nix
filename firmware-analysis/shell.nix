# Dev shell for analysing the GPD Win Max 2 (2025, HX 370) firmware.
# Enter with: nix develop .#firmware
{ pkgs }:

pkgs.mkShell {
  name = "firmware-analysis";

  packages = with pkgs; [
    # Unpacking vendor archives (RAR5 needs unar; 7zz lacks the codec)
    unar
    _7zz
    unzip

    # UEFI image structure: UEFIExtract/UEFIFind, alt. parser, HII/IFR setup forms
    uefitool
    uefi-firmware-parser
    ifrextractor-rs
    efitools

    # AMD specifics: PSP directory/firmware entries (ABL, SMU, ...), s2idle/BIOS debug
    psptool
    amd-debug-tools

    # ACPI: iasl/acpixtract/acpidump, and firmware test suite for the live system
    acpica-tools
    fwts
    dmidecode

    # Reverse engineering
    (ghidra.withExtensions (p: [ p.ghidra-firmware-utils ]))
    rizin
    binwalk
    imhex
    vbindiff

    python3
  ];

  shellHook = ''
    export FW_ROOT="$(git rev-parse --show-toplevel)/firmware-analysis"
    export PATH="$FW_ROOT/scripts:$PATH"
    echo "firmware-analysis shell — see $FW_ROOT/README.md"
  '';
}

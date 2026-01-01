# Patching DSDT

```
sudo cat /sys/firmware/acpi/tables/DSDT > dsdt.aml
nix shell nixpkgs#acpica-tools.out -c iasl -d dsdt.aml
```
Edit the file, fix `_SB.LID0._STA` to always return `0x0F`

Update the version number at the end of the header in the file by incrementing the last number `DefinitionBlock ("", "DSDT", 2, "ALASKA", "A M I ", 0x01072010)`
```
nix shell nixpkgs#acpica-tools.out -c iasl -ve -tc dsdt.dsl
mkdir -p kernel/firmware/acpi
cp dsdt.aml kernel/firmware/acpi
find kernel | cpio -H newc --create > acpi_override
```

Add the file to the bootloader configuration
```
  boot.initrd.prepend = [ "${./dsdt/acpi_override}" ];
```

{

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/EFI";
    fsType = "vfat";
    options = [ "relatime" ];
  };
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/65de6b98-348e-454f-a57a-d100cf19bd28";
    fsType = "btrfs";
    options = [
      "discard=async"
      "relatime"
      "subvol=root"
      "compress=lzo"
    ];
  };
  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/65de6b98-348e-454f-a57a-d100cf19bd28";
    fsType = "btrfs";
    options = [
      "discard=async"
      "relatime"
      "subvol=home"
      "compress=lzo"
    ];
  };

  boot.initrd.luks.devices."crypt-ssd".device =
    "/dev/disk/by-uuid/c822c962-094c-45bc-bb24-ea57062f02a4";
  boot.initrd.luks.devices."crypt-ssd".allowDiscards = true;
  swapDevices = [
    {
      device = "/dev/disk/by-partlabel/crypt-swap";
      randomEncryption.enable = true;
    }
  ];
  systemd.units."dev-sdc2.swap".enable = false;
}

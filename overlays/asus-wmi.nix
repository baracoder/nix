self: super:
let asus_wmi_nixpkgs_tar = (builtins.fetchTarball { url ="https://github.com/voanhduy1512/nixpkgs/archive/add_asus_wmi_sensors.tar.gz";} );
    asus_wmi = import (asus_wmi_nixpkgs_tar + "/pkgs/os-specific/linux/asus-wmi-sensors/" );
    callPackage = super.lib.callPackageWith super;
in
{


    linuxPackagesFor = kernel:
        (super.linuxPackagesFor kernel).extend (self': super': {
        asus-wmi-sensors = super'.callPackage asus_wmi {};
    });
}
self: super:
{
    psensor = super.psensor.overrideAttrs (a: {
        patches = [ ../pkgs/psensor.diff ];
    });

    immersed-vr = super.immersed-vr.overrideAttrs (a: {
        version = "10.0";
        src = super.fetchurl {
            url = "https://static.immersed.com/dl/Immersed-x86_64.AppImage";
            hash = "sha256-o/3nVeOwSMFI9EhHBKeN3ss8Bfmse9LMIegrd9v7Uj4=";
        };
    });

}

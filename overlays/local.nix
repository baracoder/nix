self: super:
{
    psensor = super.psensor.overrideAttrs (a: {
        patches = [ ../pkgs/psensor.diff ];
    });

    immersed-vr = super.immersed-vr.overrideAttrs (a: {
        version = "9.10";
        src = super.fetchurl {
            url = "https://static.immersed.com/dl/Immersed-x86_64.AppImage";
            hash = "sha256-tmtDe39ZAsg9p7GolNjs7CIkPOuuZ1EAq9OLtZ2g8b4=";
        };
    });

    appimageTools = super.callPackage ../pkgs/appimage { };

}

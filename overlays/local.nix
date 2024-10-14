self: super:
{
    immersed-vr = super.immersed-vr.overrideAttrs (a: {
        version = "10.0";
        src = super.fetchurl {
            url = "https://web.archive.org/web/20240411143649/https://static.immersed.com/dl/Immersed-x86_64.AppImage";
            hash = "sha256-ZY9pwOryADkpbMLx1w5Lymx6iQ0BhIrFAAvy47wLnQ8=";
        };
    });

    appimageTools = super.callPackage ../pkgs/appimage { };

    drata-agent = super.callPackage ../pkgs/drata-agent.nix { };

}

self: super:
{
    psensor = super.psensor.overrideAttrs (a: {
        patches = [ ../pkgs/psensor.diff ];
    });

    immersed-vr = super.immersed-vr.overrideAttrs (a: {
        version = "9.10";
        src = super.fetchurl {
            url = "https://static.immersed.com/dl/Immersed-x86_64.AppImage";
            hash = "sha256-NwO8nJqwLnr4wi+MSoXaJwsPi8zSlFQ8hNsIscdEcw8=";
        };
    });

    appimageTools = super.callPackage ../pkgs/appimage { };

}

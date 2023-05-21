self: super:
{
    psensor = super.psensor.overrideAttrs (a: {
        patches = [ ../pkgs/psensor.diff ];
    });

    orcaslicer = super.appimageTools.wrapType2 rec {
        pname = "orcaslicer";
        version = "1.6.2";
        src =
            let extracted = super.pkgs.fetchzip {
                url = "https://github.com/SoftFever/OrcaSlicer/releases/download/v${version}/OrcaSlicer_V${version}_Linux_ubuntu.zip";
                sha256 = "sha256-QGxrouWOUubjlVx6dQgGpYQr0HmJIMnr63sJdm6Wnr0=";
            };
            in "${extracted}/OrcaSlicer_ubu64.AppImage";
        extraPkgs = pkgs: with pkgs; [
            webkitgtk
         ];
    };


}

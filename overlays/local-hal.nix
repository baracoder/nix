self: super:
{

    #prismatik = super.libsForQt5.callPackage ../pkgs/prismatik.nix {};
    psensor = super.psensor.overrideAttrs (a: {
        patches = [ ../pkgs/psensor.diff ];
    });

}
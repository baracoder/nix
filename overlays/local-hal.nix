self: super:
{
    psensor = super.psensor.overrideAttrs (a: {
        patches = [ ../pkgs/psensor.diff ];
    });

}

self: super:
{
    psensor = super.psensor.overrideAttrs (a: {
        patches = [ ../pkgs/psensor.diff ];
    });
    orca-slicer = super.bambu-studio.overrideDerivation (old: {
        name = "orca-slicer-1.8.1";
        src = super.fetchFromGitHub {
        owner = "SoftFever";
        repo = "OrcaSlicer";
        rev = "v1.8.1";
        hash = "sha256-3aIVi7Wsit4vpFrGdqe7DUEC6HieWAXCdAADVtB5HKc=";
        };
    });


}

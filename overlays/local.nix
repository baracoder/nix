self: super:
{
    appimageTools = super.callPackage ../pkgs/appimage { };

    drata-agent = super.callPackage ../pkgs/drata-agent.nix { };

}

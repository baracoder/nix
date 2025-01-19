self: super:
{
    appimageTools = super.callPackage ../pkgs/appimage { };

    drata-agent = super.callPackage ../pkgs/drata-agent.nix { };

    offload-game = super.callPackage ../pkgs/offload-game { };


    libfprint = super.libfprint.overrideAttrs (oldAttrs: {
        version = "git";
        src = self.fetchFromGitHub {
          owner = "ericlinagora";
          repo = "libfprint-CS9711";
          rev = "c242a40fcc51aec5b57d877bdf3edfe8cb4883fd";
          sha256 = "sha256-WFq8sNitwhOOS3eO8V35EMs+FA73pbILRP0JoW/UR80=";
        };
        nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
          self.opencv
          self.cmake
          self.doctest
        ];
      });
}

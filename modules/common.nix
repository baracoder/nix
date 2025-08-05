{
  pkgs,
  ...
}:
{

  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [
        "root"
        "@wheel"
      ];
      substituters = [
        "https://cache.nixos.org/"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];

    };
    gc = {
      options = "--delete-older-than 30d";
    };
  };
  nixpkgs.config.allowUnfree = true;

  #documentation.man.generateCaches = false;

  environment.systemPackages = [
    (pkgs.callPackage ../pkgs/vim.nix { })
    (pkgs.dotnetCorePackages.combinePackages (
      with pkgs.dotnetCorePackages;
      [
        sdk_9_0
        sdk_8_0
      ]
    ))
  ];

  # directly run the missing commands via nix-shell (without installing anything)
  environment.variables.NIX_AUTO_RUN = "1";

}

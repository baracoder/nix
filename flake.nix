{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.ny.url = "git+ssh://git@git.nyris.io:10022/nyris/ny?ref=main";
  inputs.nixos-hardware.url = github:NixOS/nixos-hardware/master;

  inputs.nix-alien = {
    url = "github:thiagokokada/nix-alien";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.nixgl = {
    url = "github:guibou/nixGL";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-alien, ny, nixos-hardware, nixgl}: {
      legacyPackages = nixpkgs.legacyPackages;
      nixosConfigurations = {
        hex = nixpkgs.lib.nixosSystem rec {
            system = "x86_64-linux";
            modules = [
                ({pkgs, ...}: {
                    nixpkgs.overlays = [
                        nix-alien.overlay
                        nixgl.overlay
                    ];
                    environment.systemPackages = [
                        pkgs.nix-alien
                        pkgs.nix-index
                        pkgs.nix-index-update
                        pkgs.nixgl.nixGLIntel
                    ];
                })
                nixos-hardware.nixosModules.framework
                ny.nixosModules.x86_64-linux.ny
                ./machines/common.nix
                ./machines/hex.nix
                nixpkgs.nixosModules.notDetected

            ];
        };
        hal = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            #specialArgs = { inherit self; };

            modules = [
                ({pkgs, ...}: {
                    nixpkgs.overlays = [
                        (import ./overlays/local-hal.nix )
                        nix-alien.overlay
                    ];
                    environment.systemPackages = [
                        pkgs.nix-alien
                        pkgs.nix-index
                        pkgs.nix-index-update
                    ];
                })
                ny.nixosModules.x86_64-linux.ny
                ./machines/common.nix
                ./machines/hal.nix
                nixpkgs.nixosModules.notDetected
            ];
        };
      };
  };
}

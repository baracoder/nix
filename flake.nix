{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.ny.url = "git+ssh://git@git.nyris.io:10022/nyris/ny?ref=main";
  inputs.nixos-hardware.url = github:NixOS/nixos-hardware/master;

  inputs.nix-alien = {
    url = "github:thiagokokada/nix-alien";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.nix-ld = {
    url = "github:Mic92/nix-ld/main";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-alien, nix-ld, ny, nixos-hardware}: {
      legacyPackages = nixpkgs.legacyPackages;
      nixosConfigurations = {
        hex = nixpkgs.lib.nixosSystem rec {
            system = "x86_64-linux";
            modules = [ 
                ny.nixosModules.x86_64-linux.ny
                ./machines/common.nix
                ./machines/hex.nix
                nixpkgs.nixosModules.notDetected
                nixos-hardware.nixosModules.dell-xps-13-9380

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
                nix-ld.nixosModules.nix-ld
                ny.nixosModules.x86_64-linux.ny
                ./machines/common.nix
                ./machines/hal.nix
                nixpkgs.nixosModules.notDetected
            ];
        };
      };
  };
}

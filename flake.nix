{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.ny.url = "git+ssh://git@git.nyris.io:10022/nyris/ny?ref=main";
  inputs.nixos-hardware.url = github:NixOS/nixos-hardware/master;

  outputs = { self, nixpkgs, ny, nixos-hardware } @ inputs: {
      legacyPackages = nixpkgs.legacyPackages;
      nixosConfigurations = {
        hex = nixpkgs.lib.nixosSystem rec {
            system = "x86_64-linux";
            specialArgs = { inherit inputs; };
            modules = [
                ({pkgs, ...}: {
                    nixpkgs.overlays = [
                        (import ./overlays/local.nix )
                    ];
                    environment.systemPackages = [
                    ];
                })
                nixos-hardware.nixosModules.framework-11th-gen-intel
                #nixos-hardware.nixosModules.dell-xps-13-9380
                ny.nixosModules.x86_64-linux.ny
                ./modules/common.nix
                ./machines/hex.nix
                nixpkgs.nixosModules.notDetected

            ];
        };
        hal = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = { inherit inputs; };

            modules = [
                ({pkgs, ...}: {
                    nixpkgs.overlays = [
                        (import ./overlays/local.nix )
                    ];
                    environment.systemPackages = [
                    ];
                })
                ny.nixosModules.x86_64-linux.ny
                ./modules/common.nix
                ./machines/hal.nix
                nixpkgs.nixosModules.notDetected
            ];
        };
      };
  };
}

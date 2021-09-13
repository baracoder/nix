{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.ny.url = "git+ssh://git@git.nyris.io:10022/nyris/ny?ref=main";
  inputs.nixos-hardware.url = github:NixOS/nixos-hardware/master;
  inputs.nix-autobahn.url = github:Lassulus/nix-autobahn;

  outputs = { self, nixpkgs, nix-autobahn, ny, nixos-hardware}: {
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
        hal = nixpkgs.lib.nixosSystem rec {
            system = "x86_64-linux";
            modules = [ 
                {
                    nixpkgs.overlays = [ 
                        (import ./overlays/local-hal.nix)
                    ];
                    environment.systemPackages = [
                        nix-autobahn.packages.x86_64-linux.nix-autobahn
                    ];
                }
                ny.nixosModules.x86_64-linux.ny
                ./machines/common.nix
                ./machines/hal.nix
                nixpkgs.nixosModules.notDetected
            ];
        };
      };
  };
}

{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs}: {
      nixosConfigurations = {
        hex = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ 
                ./common.nix
                ./hex.nix
                nixpkgs.nixosModules.notDetected
            ];
        };
        hal = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ 
                ./common.nix
                ./hal.nix
                nixpkgs.nixosModules.notDetected
            ];
        };
        reason = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ 
                ./common.nix
                ./reason.nix
                nixpkgs.nixosModules.notDetected
            ];
        };
      };
  };
}

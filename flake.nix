{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.ny.url = "git+ssh://git@git.nyris.io:10022/nyris/ny?ref=main";
  outputs = { self, nixpkgs, ny}: {
      nixosConfigurations = {
        hex = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ 
                ny.nixosModules.ny
                ./common.nix
                ./hex.nix
                nixpkgs.nixosModules.notDetected
            ];
        };
        hal = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ 
                ny.nixosModules.ny
                ./common.nix
                ./hal.nix
                nixpkgs.nixosModules.notDetected
            ];
        };
        reason = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ 
                ny.nixosModules.ny
                ./common.nix
                ./reason.nix
                nixpkgs.nixosModules.notDetected
            ];
        };
      };
  };
}

{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.ny.url = "git+ssh://git@git.nyris.io:10022/nyris/ny?ref=main";
  inputs.nixos-hardware.url = github:NixOS/nixos-hardware/master;

  outputs = { self, nixpkgs, ny, nixos-hardware}: {
      nixosConfigurations = {
        hex = nixpkgs.lib.nixosSystem rec {
            system = "x86_64-linux";
            modules = [ 
                ny.nixosModules.${system}.ny
                ./machines/common.nix
                ./machines/hex.nix
                nixpkgs.nixosModules.notDetected
                nixos-hardware.nixosModules.dell-xps-13-9380

            ];
        };
        hal = nixpkgs.lib.nixosSystem rec {
            system = "x86_64-linux";
            modules = [ 
                ny.nixosModules.${system}.ny
                ./machines/common.nix
                ./machines/hal.nix
                nixpkgs.nixosModules.notDetected
            ];
        };
      };
  };
}

{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.ny.url = "git+ssh://git@github.com/baracoder/nyris-nix-overlay?ref=main";
  inputs.nixos-hardware.url = github:NixOS/nixos-hardware/master;

  outputs = { self, nixpkgs, ny, nixos-hardware}: {
      nixosConfigurations = {
        hex = nixpkgs.lib.nixosSystem rec {
            system = "x86_64-linux";
            modules = [ 
                ny.nixosModules.ny
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
                        (import ./overlays/egl-wayland.nix)
                    ];
                }
                ny.nixosModules.ny
                ./machines/common.nix
                ./machines/hal.nix
                nixpkgs.nixosModules.notDetected
            ];
        };
      };
  };
}

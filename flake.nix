{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.ny.url = "git+ssh://git@git.nyris.io:10022/nyris/ny?ref=main";
  inputs.nixos-hardware.url = github:NixOS/nixos-hardware/master;
  inputs.hyprland.url = "github:hyprwm/Hyprland";
  inputs.gBar.url = "github:scorpion-26/gBar";

  outputs = { self, nixpkgs, ny, nixos-hardware, hyprland, gBar} @ inputs: {
      legacyPackages = nixpkgs.legacyPackages;
      nixosConfigurations = {
        hex = nixpkgs.lib.nixosSystem rec {
            system = "x86_64-linux";
            specialArgs = { inherit inputs; };
            modules = [
                ({pkgs, ...}: {
                    environment.systemPackages = [
			gBar.defaultPackage.x86_64-linux
                    ];
                })
                nixos-hardware.nixosModules.framework-11th-gen-intel
                #nixos-hardware.nixosModules.dell-xps-13-9380
                ny.nixosModules.x86_64-linux.ny
                ./modules/common.nix
                ./modules/hyprland.nix
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
                        (import ./overlays/local-hal.nix )
                    ];
                    environment.systemPackages = [
                    ];
                })
                ny.nixosModules.x86_64-linux.ny
                ./modules/common.nix
                ./modules/hyprland.nix
                ./machines/hal.nix
                nixpkgs.nixosModules.notDetected
            ];
        };
      };
  };
}

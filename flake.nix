{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";

  outputs = { self, nixpkgs, nixos-hardware } @ inputs: {
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
                ./modules/common.nix
                ./machines/hex
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
                ./modules/common.nix
                ./machines/hal
                nixpkgs.nixosModules.notDetected
            ];
        };
        iso-minimal = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
                "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal-new-kernel-no-zfs.nix"
                ./machines/iso-minimal
            ];
        };
      };
  };
}

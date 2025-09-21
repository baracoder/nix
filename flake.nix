{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  inputs.nix-darwin.url = "github:LnL7/nix-darwin";
  inputs.nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixpkgs-xr.url = "github:nix-community/nixpkgs-xr";

  outputs =
    {
      nixpkgs,
      nixos-hardware,
      nix-darwin,
      nixpkgs-xr,
      ...
    }@inputs:
    {
      legacyPackages = nixpkgs.legacyPackages;
      nixosConfigurations = {
        hal = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };

          modules = [
            ./modules/common.nix
            ./modules/linux.nix
            ./modules/common-packages
            ./modules/gnome
            ./modules/gaming
            ./machines/hal
            nixpkgs.nixosModules.notDetected
            nixos-hardware.nixosModules.common-pc-laptop
            nixos-hardware.nixosModules.common-pc-laptop-ssd
            nixos-hardware.nixosModules.common-hidpi
            nixpkgs-xr.nixosModules.nixpkgs-xr
          ];
        };
        glados-nixos-vm = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            ./machines/glados-nixos-vm
          ];
        };

        killswitch = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./modules/common.nix
            ./modules/linux.nix
            ./modules/common-packages
            ./modules/gnome
            ./modules/falcon-sensor
            ./machines/killswitch
            nixos-hardware.nixosModules.lenovo-thinkpad-x1-11th-gen
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
      darwinConfigurations.glados = nix-darwin.lib.darwinSystem {
        modules = [
          ./modules/common.nix
          ./modules/common-packages
          ./machines/glados
        ];
      };
    };
}

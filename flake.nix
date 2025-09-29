{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  inputs.nixpkgs-xr.url = "github:nix-community/nixpkgs-xr";
  inputs.helix.url = "github:helix-editor/helix";

  outputs =
    {
      nixpkgs,
      nixos-hardware,
      nixpkgs-xr,
      helix,
      ...
    }@inputs:
    let
      legacyPackages = nixpkgs.legacyPackages;
    in
    {
      inherit legacyPackages;
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
            #nixpkgs-xr.nixosModules.nixpkgs-xr
            {
              nixpkgs.overlays = [
                helix.overlays.helix
                (final: prev: {
                  xrizer = nixpkgs-xr.packages.x86_64-linux.xrizer;
                  wlx-overlay-s = nixpkgs-xr.packages.x86_64-linux.wlx-overlay-s;
                })
              ];
            }
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
            {
              nixpkgs.overlays = [
                helix.overlays.helix
              ];
            }
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

{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  # inputs.nixpkgs-xr.url = "github:nix-community/nixpkgs-xr";
  inputs.nixpkgs-patcher.url = "github:gepbird/nixpkgs-patcher";

  # inputs.nixpkgs-patch-add-amd-debug-tools = {
  #   url = "https://github.com/NixOS/nixpkgs/pull/436966.diff";
  #   flake = false;
  # };

  outputs =
    {
      self,
      nixpkgs,
      nixos-hardware,
      # nixpkgs-xr,
      nixpkgs-patcher,
      ...
    }@inputs:
    {
      overlays.default = import ./overlays/local.nix;

      legacyPackages = nixpkgs.legacyPackages;
      nixosConfigurations = {
        hal = nixpkgs-patcher.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = inputs;

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
            nixos-hardware.nixosModules.common-cpu-amd
            nixos-hardware.nixosModules.common-cpu-amd-pstate
            nixos-hardware.nixosModules.common-gpu-amd
            {
              nixpkgs.overlays = [
                self.overlays.default
                (final: prev: {
                  # Currently all are recent enough
                  # wivrn = nixpkgs-xr.packages.x86_64-linux.wivrn;
                  # xrizer = nixpkgs-xr.packages.x86_64-linux.xrizer;
                  # wlx-overlay-s = nixpkgs-xr.packages.x86_64-linux.wlx-overlay-s;
                })
              ];
            }
          ];
        };

        killswitch = nixpkgs-patcher.lib.nixosSystem {
          specialArgs = inputs;
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
                self.overlays.default
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

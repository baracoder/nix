{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.ny.url = "git+ssh://git@git.nyris.io:10022/nyris/ny?ref=main";
  inputs.nixos-hardware.url = github:NixOS/nixos-hardware/master;
  inputs.hyprland.url = "github:hyprwm/Hyprland";


  inputs.nixgl = {
    url = "github:guibou/nixGL";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, ny, nixos-hardware, nixgl, hyprland} @ inputs: {
      legacyPackages = nixpkgs.legacyPackages;
      nixosConfigurations = {
        hex = nixpkgs.lib.nixosSystem rec {
            system = "x86_64-linux";
            specialArgs = { inherit inputs; };
            modules = [
                ({pkgs, ...}: {
                    nixpkgs.overlays = [
                        nixgl.overlay
                    ];
                    environment.systemPackages = [
                        pkgs.nixgl.nixGLIntel
                    ];
                })
                nixos-hardware.nixosModules.framework
                ny.nixosModules.x86_64-linux.ny
                ./machines/common.nix
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
                ./machines/common.nix
                ./machines/hal.nix
                nixpkgs.nixosModules.notDetected
            ];
        };
      };
  };
}

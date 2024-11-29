# Use

Experimental [flakes support](https://www.tweag.io/blog/2020-07-31-nixos-flakes/) is required.
https://www.tweag.io/blog/2020-07-31-nixos-flakes/


```
nh os switch --flake .#hostname
```

`#host-name` is optional `sudo nixos-rebuild --flake .` will use the current name of the host.

Note: untracked files won't be copied to store. Use `git add` first, to build from a dirty directory.

To update nixpkgs input to latest unstable:
```
nix flake update --update-input nixpkgs
```


# Install on new machine

## Prepare install media

Create a minimal install media with all required tools and kernel modules using the following command:
```
nix build .\#nixosConfigurations.iso-minimal.config.system.build.isoImage
```

Write the resulting iso to a USB stick:
```
sudo dd bs=4M conv=fsync oflag=direct status=progress if=result/iso/*.iso of=/dev/sdX
```

## Install

* Boot prepared install media
* Clone the repo to some directory
* Run the installation `nixos-install --flake /path/to/repo#-new-host`

## Darwin

For the initial install
```
nix run nix-darwin -- switch --flake .
```
Afer that, just
```
darwin-rebuild switch --flake .
```

### Darwin NixOS VM

Bootstrap using the [darwin builder](https://nixos.org/manual/nixpkgs/unstable/#sec-darwin-builder)

# Use

Experimental [flakes support](https://www.tweag.io/blog/2020-07-31-nixos-flakes/) is required.
https://www.tweag.io/blog/2020-07-31-nixos-flakes/


```
sudo nixos-rebuild switch --flake .#hostname
```

`#host-name` is optional `sudo nixos-rebuild --flake .` will use the current name of the host.

Note: untracked files won't be copied to store. Use `git add` first, to build from a dirty directory.

To update nixpkgs input to latest unstable:
```
nix flake update --update-input nixpkgs
```

# Install on new machine

This repo uses `flakes` which is an experimental feature at this point and not supported by the default nix version.

* Boot from NixoOS 20.09 install media
* Enter a shell with git and an updated nix version `nix-shell -p git nixFlakes
* Clone the repo to some directory on newly created `/mnt/` partition
* Copy a machine file `cp machines/hex.nix machines/new-host.nix`
* Modify new file
    * `filesystem`
    * Kernel modules & video drivers
* Add new entry to `flake.nix`
* Create a commit or at least `git add` the new machine file
* Run the installation `nixos-install --flake /path/to/repo#-new-host`
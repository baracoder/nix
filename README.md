# Use

Experimental [flakes support](https://www.tweag.io/blog/2020-07-31-nixos-flakes/) is required.
https://www.tweag.io/blog/2020-07-31-nixos-flakes/


```
sudo nixos-rebuild switch --flake .#hostname
```

`#host-name` is optional `sudo nixos-rebuild --flake .` will use the current name of the host.

Note: untracked files won't be copied to store. Use `git add` first, to build from a dirty directory.
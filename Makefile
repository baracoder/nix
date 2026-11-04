update: link
	nix flake update
	nh os boot .
	git commit -m 'Update flake inputs' ./flake.lock
	nh clean all -K 30d --no-direnv

update-packages:
	nix-update --flake nixosConfigurations.killswitch.pkgs.csharp-language-server

switch: link
	nh os switch .

# Symlink dotfiles/ into $HOME (see scripts/link-home).
link:
	./scripts/link-home

.PHONY: update update-packages switch link

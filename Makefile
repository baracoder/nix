update:
	nix flake update
	nh os boot .
	git commit -m 'Update flake inputs' ./flake.lock
	nh clean all -K 30d

update-packages:
	nix-update --flake nixosConfigurations.killswitch.pkgs.csharp-language-server

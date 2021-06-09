# https://github.com/NixOS/nixpkgs/issues/124308

self: super:
{

    steam = super.steam.override { extraPkgs = pkgs: [ pkgs.pipewire.lib ]; };
}
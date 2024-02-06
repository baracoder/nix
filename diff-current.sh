#!/bin/sh

sudo nixos-rebuild build --flake .
nix store diff-closures /run/current-system ./result
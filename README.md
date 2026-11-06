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
After that, just
```
darwin-rebuild switch --flake .
```

### Darwin NixOS VM

Bootstrap using the [darwin builder](https://nixos.org/manual/nixpkgs/unstable/#sec-darwin-builder)

# Patches to upstream

Local patches carried in this repo, to send upstream and drop once merged.
The ionwl ones are `git format-patch` output from a checkout of
`codeberg.org/ideasman42/ionwl` with the patches applied in order, so each
can be sent as it is.

- [ ] `overlays/patches/gnome-shell-gvc-null-active-profile.patch`: gvc crashes
  on a sound card with no active profile, which kills gnome-shell
  ([libgnome-volume-control](https://gitlab.gnome.org/GNOME/libgnome-volume-control))
- [ ] `overlays/patches/upower-battery-other-audio.patch`: headphones icon for
  devices UPower reports as `OTHER_AUDIO`
  ([upower-battery](https://extensions.gnome.org/extension/5165/upower-battery/))
- [ ] `pkgs/ionwl/primary-gpu-override.patch`: `IONWL_PRIMARY_GPU` picks the
  render GPU ([ionwl](https://codeberg.org/ideasman42/ionwl))
- [ ] `pkgs/ionwl/touchpad-detection.patch`: touchpads get touchpad prefs, not
  mouse prefs ([ionwl](https://codeberg.org/ideasman42/ionwl))
- [ ] `pkgs/ionwl/ext-idle-notify.patch`: ext-idle-notify, listed under "Not
  Yet Supported" in ionwl's docs ([ionwl](https://codeberg.org/ideasman42/ionwl))
- [ ] `pkgs/ionwl/wheel-bindings.patch`: bind scroll-wheel detents with
  `MatchPointer(btn.WHEEL_UP)` etc. ([ionwl](https://codeberg.org/ideasman42/ionwl))
- [ ] `pkgs/ionwl/ext-workspace.patch`: ext-workspace, for workspace switchers
  in bars ([ionwl](https://codeberg.org/ideasman42/ionwl))
- [ ] `pkgs/ionwl/tearing-control.patch`: wp-tearing-control, async page flips
  for fullscreen games ([ionwl](https://codeberg.org/ideasman42/ionwl)); needs
  the smithay patch below first
- [ ] `pkgs/ionwl/smithay-drm-async-page-flip.patch`: backport of the unmerged
  [Smithay/smithay#1948](https://github.com/Smithay/smithay/pull/1948) plus a
  capability check; comment on the PR rather than send a new one
- [ ] `pkgs/ionwl/pointer-gestures.patch`: touchpad swipe/pinch/hold for
  clients ([ionwl](https://codeberg.org/ideasman42/ionwl))
- [ ] `pkgs/ionwl/xwayland-ready-hook.patch`: `xwayland_ready_post` hook, as
  DISPLAY otherwise never reaches the session environment
  ([ionwl](https://codeberg.org/ideasman42/ionwl))
- [ ] `pkgs/ionwl/tiled-drag.patch`: `window_drag` and `frame_resize_drag`, to
  move and resize tiled windows with Super+drag from anywhere on them
  ([ionwl](https://codeberg.org/ideasman42/ionwl))
- [ ] `pkgs/ionwl/desktop-swipe.patch`: switch desktops with a touchpad or
  touchscreen swipe, and the `gesture_swipe_*` hooks behind it
  ([ionwl](https://codeberg.org/ideasman42/ionwl))
- [ ] `pkgs/ionwl/fullscreen-covers-top-layer.patch`: fullscreen windows cover
  Top-layer surfaces such as bars ([ionwl](https://codeberg.org/ideasman42/ionwl))
- [ ] `pkgs/ionwl/x11-input-focus.patch`: focused X11 windows get the X11
  input focus, which Unity games need for any input
  ([ionwl](https://codeberg.org/ideasman42/ionwl)); needs the smithay patch
  below first
- [ ] `pkgs/ionwl/smithay-x11-input-focus.patch`: `X11Surface::input_focus_take`
  and `input_focus_release`, for compositors whose keyboard focus is the
  `WlSurface` ([smithay](https://github.com/Smithay/smithay))
- [ ] `overlays/patches/mutter-tearing.patch`: CachyOS's tearing series rebased
  onto mutter 50.5; not ours to send, drop it once mutter ships tearing
  ([mutter](https://gitlab.gnome.org/GNOME/mutter))
- [ ] `pkgs/way-shell/ionwl-backend.patch`: ionwl window-manager backend
  ([way-shell](https://github.com/ldelossa/way-shell))
- [ ] `pkgs/linzone-hub/package.nix` `postPatch`: the udev rule assigns
  `ENV{UPOWER_BATTERY_TYPE}:=`, but udev has no `:=` for `ENV`
  ([linzone-hub](https://github.com/patyhank/linzone-hub))

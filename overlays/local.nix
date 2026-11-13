final: prev:
(prev.lib.filesystem.packagesFromDirectoryRecursive {
  callPackage = final.callPackage;
  directory = ../pkgs;
})
// {
  # substitute broken package with evaluation log
  broken =
    pkg: reason:
    let
      # A package can be broken badly enough that even reading its name throws.
      name = builtins.tryEval (final.lib.getName pkg);
    in
    final.lib.warn "broken package ${if name.success then name.value else "<unknown>"}: ${reason}" final.emptyDirectory;

  # gnome-shell segfaults in libgvc when pipewire-pulse reports an audio card
  # with no active profile, which happens while a USB device is still settling.
  # Losing that race at login kills the whole session and drops back to GDM.
  #
  # Quick settings keeps direct scanout disabled on 51.0 (gnome-shell!4470).
  # Fixed in 51.1; drop once nixpkgs ships it (NixOS/nixpkgs#584116).
  gnome-shell = prev.gnome-shell.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./patches/gnome-shell-gvc-null-active-profile.patch
    ]
    ++ prev.lib.optionals (prev.lib.versionOlder old.version "51.1") [
      ./patches/gnome-shell-boxpointer-unredirect.patch
    ];
  });

  # Async page flips (wp_tearing_control_v1) for lower-latency fullscreen
  # games. CachyOS's series, squashed; off unless the "tearing" experimental
  # feature is enabled.
  mutter = prev.mutter.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./patches/mutter-tearing.patch
    ];
  });

  gnomeExtensions = prev.gnomeExtensions // {
    upower-battery = prev.gnomeExtensions.upower-battery.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [
        ./patches/upower-battery-other-audio.patch
      ];
    });
  };

  google-chrome = prev.google-chrome.override {
    commandLineArgs = "--enable-features=TouchpadOverscrollHistoryNavigation";
  };

  vivaldi = prev.vivaldi.override {
    commandLineArgs = "--enable-features=TouchpadOverscrollHistoryNavigation";
  };
}

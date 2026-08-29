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
  gnome-shell = prev.gnome-shell.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./patches/gnome-shell-gvc-null-active-profile.patch
    ];
  });

  google-chrome = prev.google-chrome.override {
    commandLineArgs = "--enable-features=TouchpadOverscrollHistoryNavigation";
  };

  vivaldi = prev.vivaldi.override {
    commandLineArgs = "--enable-features=TouchpadOverscrollHistoryNavigation";
  };
}

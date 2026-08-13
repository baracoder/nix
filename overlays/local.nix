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

  google-chrome = prev.google-chrome.override {
    commandLineArgs = "--enable-features=TouchpadOverscrollHistoryNavigation";
  };

  vivaldi = prev.vivaldi.override {
    commandLineArgs = "--enable-features=TouchpadOverscrollHistoryNavigation";
  };
}

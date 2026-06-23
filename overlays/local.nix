final: prev:
(prev.lib.filesystem.packagesFromDirectoryRecursive {
  callPackage = final.callPackage;
  directory = ../pkgs;
})
// {
  google-chrome = prev.google-chrome.override {
    commandLineArgs = "--enable-features=TouchpadOverscrollHistoryNavigation";
  };

  vivaldi = prev.vivaldi.override {
    commandLineArgs = "--enable-features=TouchpadOverscrollHistoryNavigation";
  };
}

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
  # Until next verion relesed
  handheld-daemon = prev.handheld-daemon.overrideAttrs (oldAttrs: {
    patches = oldAttrs.patches ++ [
      (final.fetchurl {
        url = "https://patch-diff.githubusercontent.com/raw/hhd-dev/hhd/pull/334.diff";
        hash = "sha256-FCX6a6NT7UtIve/sRlKuic2jOKrnjP9sjAR6Lg6Ujcw=";
      })
    ];
  });
}

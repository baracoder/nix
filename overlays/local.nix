final: prev: {
  google-chrome = prev.google-chrome.override {
    commandLineArgs = "--enable-features=TouchpadOverscrollHistoryNavigation";
  };

  vivaldi = prev.vivaldi.override {
    commandLineArgs = "--enable-features=TouchpadOverscrollHistoryNavigation";
  };

  offload-game = final.callPackage ../pkgs/offload-game { };

  egpu = final.callPackage ../pkgs/egpu { };

  pywincontrols = final.callPackage ../pkgs/pywincontrols { };

  csharp-language-server = final.callPackage ../pkgs/csharp-language-server/package.nix { };
}

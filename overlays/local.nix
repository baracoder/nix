final: prev: {
  google-chrome = prev.google-chrome.override {
    commandLineArgs = "--enable-features=TouchpadOverscrollHistoryNavigation";
  };

  vivaldi = prev.vivaldi.override {
    commandLineArgs = "--enable-features=TouchpadOverscrollHistoryNavigation";
  };

  offload-game = final.callPackage ../pkgs/offload-game { };

  egpu = final.callPackage ../pkgs/egpu { };

  adjustor = final.callPackage ../pkgs/adjustor { };

  pywincontrols = final.callPackage ../pkgs/pywincontrols { };

  handheld-daemon = prev.handheld-daemon.overrideAttrs (oldAttrs: {
    propagatedBuildInputs = oldAttrs.propagatedBuildInputs ++ [
      final.adjustor
    ];
  });

  xrizer = prev.xrizer.overrideAttrs {
    version = "main";
    src = final.fetchFromGitHub {
      owner = "Supreeeme";
      repo = "xrizer";
      #ref = "elite-dangerous-fixes";
      rev = "6a095264566114b5a7f480aefc5efb1f2b30b2af";
      sha256 = "";
    };
  };

}

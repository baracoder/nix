final: prev: {
  google-chrome = prev.google-chrome.override {
    commandLineArgs = "--enable-features=TouchpadOverscrollHistoryNavigation";
  };

  offload-game = final.callPackage ../pkgs/offload-game { };

  egpu = final.callPackage ../pkgs/egpu { };

  adjustor = final.callPackage ../pkgs/adjustor { };

  pywincontrols = final.callPackage ../pkgs/pywincontrols { };

  wivrn = (prev.wivrn.override { cudaSupport = true; });

  handheld-daemon = prev.handheld-daemon.overrideAttrs (oldAttrs: {
    propagatedBuildInputs = oldAttrs.propagatedBuildInputs ++ [
      final.adjustor
    ];
  });

  pyroveil = final.callPackage ../pkgs/pyroveil/package.nix { };

}

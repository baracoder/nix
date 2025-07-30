self: super: rec {
  google-chrome = super.google-chrome.override {
    commandLineArgs = "--enable-features=TouchpadOverscrollHistoryNavigation";
  };

  offload-game = super.callPackage ../pkgs/offload-game { };

  egpu = super.callPackage ../pkgs/egpu { };

  adjustor = super.callPackage ../pkgs/adjustor { };

  pywincontrols = super.callPackage ../pkgs/pywincontrols { };

  wivrn = (super.wivrn.override { cudaSupport = true; });

  handheld-daemon-ui = super.callPackage ../pkgs/hhd-ui.nix { };
  pyroveil = super.callPackage ../pkgs/pyroveil/package.nix { };

}

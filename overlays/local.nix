final: prev: {
  google-chrome = prev.google-chrome.override {
    commandLineArgs = "--enable-features=TouchpadOverscrollHistoryNavigation";
  };

  offload-game = final.callPackage ../pkgs/offload-game { };

  egpu = final.callPackage ../pkgs/egpu { };

  adjustor = final.callPackage ../pkgs/adjustor { };

  pywincontrols = final.callPackage ../pkgs/pywincontrols { };

  wivrn = (prev.wivrn.override { cudaSupport = true; });

  handheld-daemon =
    final.lib.trace "Remove when PR merged: https://github.com/NixOS/nixpkgs/pull/434301"
      (
        prev.handheld-daemon.overrideAttrs (oldAttrs: {
          postPatch = oldAttrs.postPatch + ''
            substituteInPlace usr/lib/udev/rules.d/83-hhd.rules \
              --replace-fail '/bin/chmod' '${final.lib.getExe' final.coreutils "chmod"}'
          '';

          postInstall = ''
            install -Dm644 usr/lib/udev/rules.d/83-hhd.rules -t $out/lib/udev/rules.d/
            install -Dm644 usr/lib/udev/hwdb.d/83-hhd.hwdb -t $out/lib/udev/hwdb.d/
          '';

          propagatedBuildInputs = oldAttrs.propagatedBuildInputs ++ [
            final.adjustor
          ];
        })
      );

  handheld-daemon-ui = final.callPackage ../pkgs/hhd-ui.nix { };
  pyroveil = final.callPackage ../pkgs/pyroveil/package.nix { };

}

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

  amd-debug-tools = final.callPackage ../pkgs/amd-debug-tools/package.nix { };

  helix = prev.helix.overrideAttrs (a: {
    patches = [
      # Completion for gitignored files in typed commands
      (final.fetchpatch {
        url = "https://github.com/helix-editor/helix/pull/12729.patch";
        hash = "sha256-bdIWGkA9s/ltdN9D8lxOauQx8LhOettuagJGFyJxDRw=";
      })
      # Clickable tabs
      (final.fetchpatch {
        url = "https://github.com/helix-editor/helix/pull/12173.patch";
        hash = "sha256-DMSyp5k9H7JOMvFdY7YXDiMqARaTDbifZb6EWmQNDJQ=";
      })
    ];
  });
}

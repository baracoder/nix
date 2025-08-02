{
  pkgs,
  ...
}:
{

  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [
        "root"
        "@wheel"
      ];
      substituters = [
        "https://cache.nixos.org/"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];

    };
    gc = {
      options = "--delete-older-than 30d";
    };
  };
  nixpkgs.config.allowUnfree = true;

  #documentation.man.generateCaches = false;

  environment.systemPackages =
    with pkgs;
    [
      bash-language-server
      btop
      codebook
      copilot-language-server
      curl
      csharp-ls
      direnv
      docker
      docker-compose
      dogdns
      dosfstools
      fd
      file
      fzf
      gimp
      git-lfs
      gitAndTools.gitFull
      gnumake
      grpcurl
      harper
      helix
      helix-gpt
      helm-ls
      htop
      imagemagick
      immersed
      jetbrains.rider
      jq
      k9s
      kube-score
      kubectl
      lazygit
      lazyjj
      lnav
      lsof
      lsp-ai
      meld
      ncdu
      netcoredbg
      nix-tree
      nixd
      nixfmt
      nmap
      nnn
      nvd
      octave
      omnisharp-roslyn
      pdfgrep
      pre-commit
      pwgen
      python3
      renameutils
      ripgrep
      samba
      skopeo
      sqlite
      terraform-ls
      tldr
      typescript-language-server
      typos-lsp
      unzip
      vscode-json-languageserver
      wget
      wireshark
      yaml-language-server
      yazi
      yq-go
      zellij
      zsh
    ]
    ++ [
      (callPackage ../pkgs/vim.nix { })
      (dotnetCorePackages.combinePackages (
        with dotnetCorePackages;
        [
          sdk_9_0
          sdk_8_0
        ]
      ))
    ];

  # directly run the missing commands via nix-shell (without installing anything)
  environment.variables.NIX_AUTO_RUN = "1";

}

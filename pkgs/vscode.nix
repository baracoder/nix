{vscode-with-extensions, vscode-utils, vscode-extensions, vscodium}:

vscode-with-extensions.override {
    vscode = vscodium;
    # When the extension is already available in the default extensions set.
    vscodeExtensions = with vscode-extensions; [
        bbenoist.nix
        mhutchie.git-graph
        ms-kubernetes-tools.vscode-kubernetes-tools
        ms-vscode-remote.remote-ssh
        ms-azuretools.vscode-docker
        haskell.haskell
        ionide.ionide-fsharp
        ms-dotnettools.csharp
        justusadam.language-haskell
        formulahendry.auto-close-tag
        redhat.vscode-yaml
        vscodevim.vim
        alanz.vscode-hie-server
        dhall.dhall-lang
        dhall.vscode-dhall-lsp-server
        streetsidesoftware.code-spell-checker
        coenraads.bracket-pair-colorizer-2
        brettm12345.nixfmt-vscode
        # https://nixpk.gs/pr-tracker.html?pr=204457
        #ms-python.python
        kubukoz.nickel-syntax
        golang.go
        ms-toolsai.jupyter
    ]
    # Concise version from the vscode market place when not available in the default set.
    ++ vscode-utils.extensionsFromVscodeMarketplace [
        {
            name = "gitblame";
            publisher = "waderyan";
            version = "10.1.0";
            sha256 = "sha256-TTYBaJ4gcMVICz4bGZTvbNRPpWD4tXuAJbI8QcHNDv0=";
        }
        {
            name = "ecdc";
            publisher = "mitchdenny";
            version = "1.8.0";
            sha256 = "sha256-W2WlngFC5pAAjkj4lQNR5yPJZiedkjqGZHldjx8m7IU=";
        }
        {
            name = "syncify";
            publisher = "arnohovhannisyan";
            version = "4.0.5";
            sha256 = "sha256-mbKy4NPcg7L31fIt8o+HyE01IyuEEE4YXGVy6led+qo=";
        }
        {
            name = "json2yaml";
            publisher = "tuxtina";
            version = "0.2.0";
            sha256 = "sha256-zj2noFRlxhvrwEVSvtbLZDxKP3yNIGAfSB95X74PW8o=";
        }
        {
            name = "dotnet-interactive-vscode";
            publisher = "ms-dotnettools";
            version = "1.0.3553071";
            sha256 = "sha256-EZIKb4CvNRZf6KxMrSPEGhxNLZ3CVCAXQg0P/894LNI=";
        }
    ];
}
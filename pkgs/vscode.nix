{vscode-with-extensions, vscode-utils, vscode-extensions, vscodium}:

vscode-with-extensions.override {
    vscode = vscodium;
    # When the extension is already available in the default extensions set.
    vscodeExtensions = with vscode-extensions; [
        bbenoist.nix
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
        ms-python.python
        kubukoz.nickel-syntax
        golang.go
        ms-toolsai.jupyter
    ]
    # Concise version from the vscode market place when not available in the default set.
    ++ vscode-utils.extensionsFromVscodeMarketplace [
        {
            name = "gitlens";
            publisher = "eamodio";
            version = "2022.11.405";
            sha256 = "sha256-01cN6PqE4g/jOWXUuWScS5qZzMmFN/70SPAVLHHsejQ=";
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
        {
            name = "aw-watcher-vscode";
            publisher = "activitywatch";
            version = "0.5.0";
            sha256 = "sha256-OrdIhgNXpEbLXYVJAx/jpt2c6Qa5jf8FNxqrbu5FfFs=";

        }
    ];
}
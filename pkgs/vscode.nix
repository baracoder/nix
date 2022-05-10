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
        eamodio.gitlens
        mhutchie.git-graph
        streetsidesoftware.code-spell-checker
        coenraads.bracket-pair-colorizer-2
        brettm12345.nixfmt-vscode
        ms-python.python
        kubukoz.nickel-syntax
    ]
    # Concise version from the vscode market place when not available in the default set.
    ++ vscode-utils.extensionsFromVscodeMarketplace [
        {
        name = "ecdc";
        publisher = "mitchdenny";
        version = "1.4.0";
        sha256 = "sha256-pP5VV1ahnYT2H5xNCVeM+APdqY132WrwJGyIX7HKYZI=";
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
            version = "1.0.3103011";
            sha256 = "sha256-W2dDbp6D2ENn3e8aqtwwQig7qkTdQUHez/wzdhvWQXs=";
        }
        {
            name = "jupyter";
            publisher = "ms-toolsai";
            version = "2022.2.1010561006";
            sha256 = "sha256-RaLslp6Q4F3oxMCJhs5WQqTsNqsGIDIPW7OD/fRSLWY=";
        }

    ];
}
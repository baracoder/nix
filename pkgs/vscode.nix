{vscode-with-extensions, vscode-utils, vscode-extensions, vscodium}:

vscode-with-extensions.override {
    vscode = vscodium;
    # When the extension is already available in the default extensions set.
    vscodeExtensions = with vscode-extensions; [
        bbenoist.Nix
        ms-kubernetes-tools.vscode-kubernetes-tools
        ms-vscode-remote.remote-ssh
        ms-azuretools.vscode-docker
        justusadam.language-haskell
        formulahendry.auto-close-tag
        redhat.vscode-yaml
        vscodevim.vim
        alanz.vscode-hie-server
        dhall.dhall-lang
        dhall.vscode-dhall-lsp-server
    ]
    # Concise version from the vscode market place when not available in the default set.
    ++ vscode-utils.extensionsFromVscodeMarketplace [
        {
        name = "vscode-power-mode";
        publisher = "hoovercj";
        version = "2.2.0";
        sha256 = "0v1vqkcsnwwbb7xbpq7dqwg1qww5vqq7rc38qfk3p6b4xhaf8scm";
        }
        {
        name = "ecdc";
        publisher = "mitchdenny";
        version = "1.4.0";
        sha256 = "sha256-pP5VV1ahnYT2H5xNCVeM+APdqY132WrwJGyIX7HKYZI=";
        }
        {
        name = "nixfmt-vscode";
        publisher = "brettm12345";
        version = "0.0.1";
        sha256 = "07w35c69vk1l6vipnq3qfack36qcszqxn8j3v332bl0w6m02aa7k";
        }
        {
        name = "gitlens";
        publisher = "eamodio";
        version = "11.3.0";
        sha256 = "sha256-m2Zn+e6hj59SujcW5ptdrYDrc4CviZ4wyCndO2BhyF8=";
        }
        {
        name = "git-graph";
        publisher = "mhutchie";
        version = "1.29.0";
        sha256 = "sha256-RTN8U+OE+Mxo2WPvPFSVYi1cEK7yLZ9paCFrqw+zpAs=";
        }
        {
        name = "code-spell-checker";
        publisher = "streetsidesoftware";
        version = "1.10.2";
        sha256 = "sha256-K8pcjjy9cPEvjsz3avFf4pmifJm4L0uSOMy34rIhgNI=";
        }
        {
        name = "syncify";
        publisher = "arnohovhannisyan";
        version = "4.0.5";
        sha256 = "sha256-mbKy4NPcg7L31fIt8o+HyE01IyuEEE4YXGVy6led+qo=";
        }
        {
        name = "bracket-pair-colorizer-2";
        publisher = "CoenraadS";
        version = "0.2.0";
        sha256 = "0nppgfbmw0d089rka9cqs3sbd5260dhhiipmjfga3nar9vp87slh";
        }


        # dotnet
        {
        name = "csharp";
        publisher = "ms-dotnettools";
        version = "1.23.9";
        sha256 = "sha256-5G3u3eqzaqP794E/i7aj4UCO6HAifGwnRKsVaFT3CZg=";
        # npm i
        # npm run compile
        }
        {
        name = "Ionide-fsharp";
        publisher = "Ionide";
        version = "5.4.1";
        sha256 = "sha256-51awfU0nL3uAzMBy5W/bPweNNgAUrWBuptPZ59VH2iw=";
        }
        {
        name = "Ionide-Paket";
        publisher = "Ionide";
        version = "2.0.0";
        sha256 = "1455zx5p0d30b1agdi1zw22hj0d3zqqglw98ga8lj1l1d757gv6v";
        }
        {
        name = "Ionide-FAKE";
        publisher = "Ionide";
        version = "1.2.3";
        sha256 = "0ijgnxcdmb1ij3szcjlyxs2lb1kly5l26lg9z2fa7hfn67rrds29";
        }

        # haskell
        {
        name = "haskell";
        publisher = "haskell";
        version = "1.2.0";
        sha256 = "sha256-nv7jFpIobEA7ZOeY1E7jLDEC0L6RkXvLxSrYIzSxum8=";
        }

        # code reviews
        {
        name = "codestream";
        publisher = "CodeStream";
        version = "10.7.2";
        sha256 = "sha256-qqNx+XeArpOWnqavzp22F18AKJzZceP/Mj6yfBL47qc=";
        }

        {
            name = "json2yaml";
            publisher = "tuxtina";
            version = "0.2.0";
            sha256 = "sha256-zj2noFRlxhvrwEVSvtbLZDxKP3yNIGAfSB95X74PW8o=";
        }

    ];
}
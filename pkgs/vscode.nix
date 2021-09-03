{vscode-with-extensions, vscode-utils, vscode-extensions, vscodium}:

vscode-with-extensions.override {
    vscode = vscodium;
    # When the extension is already available in the default extensions set.
    vscodeExtensions = with vscode-extensions; [
        bbenoist.nix
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
        version = "11.5.1";
        sha256 = "sha256-Ic7eT8WX2GDYIj/aTu1d4m+fgPtXe4YQx04G0awbwnM=";
        }
        {
        name = "git-graph";
        publisher = "mhutchie";
        version = "1.30.0";
        sha256 = "sha256-sHeaMMr5hmQ0kAFZxxMiRk6f0mfjkg2XMnA4Gf+DHwA=";
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
        version = "0.2.1";
        sha256 = "sha256-5wM0hkkTdWsTwtRshqsLPkJKnERDKWwh/mcUpoj+2y0=";
        }


        # dotnet
        {
        name = "csharp";
        publisher = "ms-dotnettools";
        version = "1.23.12";
        sha256 = "sha256-n6Auvo3KC2c/17ODF+Ey9rd8bGzypSvxsB724lIa5sg=";
        # npm i
        # npm run compile
        }
        {
        name = "Ionide-fsharp";
        publisher = "Ionide";
        version = "5.5.7";
        sha256 = "sha256-sw9RDn6Nqi7wWVlQBKN8SCs55EZZqP4ryhaCC6iwyOM=";
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
        version = "1.4.0";
        sha256 = "sha256-IE7eFsXgushgm4uClldoX1rEtPHx9uizwwos0JwAZ8o=";
        }

        # code reviews
        {
        name = "codestream";
        publisher = "CodeStream";
        version = "11.0.11";
        sha256 = "sha256-7lkdmqcR50T0IPVfp5umpnVpUR4eYUkI7tYdLsEe7rA=";
        }

        {
            name = "json2yaml";
            publisher = "tuxtina";
            version = "0.2.0";
            sha256 = "sha256-zj2noFRlxhvrwEVSvtbLZDxKP3yNIGAfSB95X74PW8o=";
        }

    ];
}
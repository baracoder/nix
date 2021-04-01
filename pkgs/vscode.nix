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
        version = "1.3.0";
        sha256 = "0hkiwxizdr9nfpgms65hw3v55qvqz3k2lnaji2lwx8bbb9iwal14";
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
        version = "10.2.1";
        sha256 = "1bh6ws20yi757b4im5aa6zcjmsgdqxvr1rg86kfa638cd5ad1f97";
        }
        {
        name = "git-graph";
        publisher = "mhutchie";
        version = "1.25.0";
        sha256 = "126s0kzq0a0rp1dagyi2ks1vr91a4p8vn4y9yk2agx46xkcf8ycq";
        }
        {
        name = "code-spell-checker";
        publisher = "streetsidesoftware";
        version = "1.9.0";
        sha256 = "0ic0zbv4pja5k4hlixmi6mikk8nzwr8l5w2jigdwx9hc4zhkf713";
        }
        {
        name = "syncify";
        publisher = "arnohovhannisyan";
        version = "4.0.4";
        sha256 = "0fii948h47k6cd0cs92zmn1kirh3p9cl2h6rbc9kdp18ng4qqd64";
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
        version = "1.22.1";
        sha256 = "1cvyn4vj20ipdmp6jhiv1a84jaxgbfpn4r1043ayassdlimvdsl8";
        # npm i
        # npm run compile
        }
        {
        name = "Ionide-fsharp";
        publisher = "Ionide";
        version = "4.14.0";
        sha256 = "0xdlknjmgn770pzpbw00gdqln9kkyksqnm1g9fcnrmclyhs639z4";
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
        version = "1.0.0";
        sha256 = "0i5dljl5m42kiwqlaplbqi4bhq59456bxs0m0w1dzk80jxyfsv0i";
        }

        # code reviews
        {
        name = "codestream";
        publisher = "CodeStream";
        version = "10.4.0";
        sha256 = "sha256-HaLKdPxpsjothkXLGFxiMxeeeVzey+b2Bpsu0yJZb6Q=";
        }

        {
            name = "json2yaml";
            publisher = "tuxtina";
            version = "0.2.0";
            sha256 = "sha256-zj2noFRlxhvrwEVSvtbLZDxKP3yNIGAfSB95X74PW8o=";
        }

    ];
}
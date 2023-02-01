{dotnetCorePackages, buildEnv, makeWrapper, lib}:
let myCombinePackages = packages:
    let cli = builtins.head packages;
    in buildEnv {
        name = "dotnet-core-combined";
        paths = packages;
        pathsToLink = [ "/host" "/packs" "/sdk" "/sdk-manifests" "/shared" "/templates" ];
        ignoreCollisions = true;
        nativeBuildInputs = [
        makeWrapper
        ];
        postBuild = ''
        cp -R ${cli}/{dotnet,share,nix-support} $out/
        mkdir $out/bin
        ln -s $out/dotnet $out/bin/dotnet
        '';
        passthru = {
            inherit (cli) icu packages;
        };
    };
in myCombinePackages  (with dotnetCorePackages; [
    sdk_7_0
    sdk_6_0
    sdk_3_1

    aspnetcore_6_0
    aspnetcore_3_1

])
{
  stdenvNoCC,
  fetchurl,
  nix-update-script,
}:

stdenvNoCC.mkDerivation rec {
  pname = "csharp-language-server";
  version = "5.3.0-2.25608.6";
  src = fetchurl {
    url = "https://github.com/SofusA/${pname}/releases/download/${version}/${pname}-x86_64-unknown-linux-gnu.tar.gz";
    sha256 = "sha256-YSRsjml/GpkM7+aPlEEp4DF+8kO3xMZhV5Quldfexo8=";
  };
  sourceRoot = ".";

  dontBuild = true;
  installPhase = ''
    install -c -D csharp-language-server $out/bin/csharp-language-server
  '';

  passthru.updateScript = nix-update-script { };
}

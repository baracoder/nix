{
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation rec {
  pname = "csharp-language-server";
  version = "5.3.0-2.25557.9";
  src = fetchurl {
    url = "https://github.com/SofusA/${pname}/releases/download/${version}/${pname}-x86_64-unknown-linux-gnu.tar.gz";
    sha256 = "sha256-ooZVz6VCMZpEjgC7hhrRSZ0ZBmWhpR+n0ulRMtTesko=";
  };
  sourceRoot = ".";

  dontBuild = true;
  installPhase = ''
    install -c -D csharp-language-server $out/bin/csharp-language-server
  '';
}

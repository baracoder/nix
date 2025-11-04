{
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation rec {
  pname = "csharp-language-server";
  version = "5.1.0-1.25501.2";
  src = fetchurl {
    url = "https://github.com/SofusA/${pname}/releases/download/${version}/${pname}-x86_64-unknown-linux-gnu.tar.gz";
    sha256 = "sha256-8oRvcY2+OS9QV583udn0L7FVjHdDrKrJ63vmygfMWbk=";
  };
  sourceRoot = ".";

  dontBuild = true;
  installPhase = ''
    install -c -D csharp-language-server $out/bin/csharp-language-server
  '';
}

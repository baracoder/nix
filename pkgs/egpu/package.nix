{stdenvNoCC}:

stdenvNoCC.mkDerivation {
  pname = "egpu-script";
  version = "2025.1";

  src = ./src;

  dontBuild = true;
  installPhase = ''
    mkdir -p $out/bin
    cp ./* $out/bin/
  '';
}
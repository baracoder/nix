{stdenvNoCC}:

stdenvNoCC.mkDerivation {
  pname = "offload-game";
  version = "2025.1";

  src = ./src;

  dontBuild = true;
  installPhase = ''
    mkdir -p $out/bin
    cp ./* $out/bin/
    ln -s $out/bin/offloadgame $out/bin/offload-game
  '';

  meta = {
    description = "Use nvidia dGPU if available";
  };
}
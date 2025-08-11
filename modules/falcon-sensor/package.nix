{
  stdenv,
  lib,
  dpkg,
  buildFHSEnv,
  requireFile,
  ...
}:

let
  pname = "falcon-sensor";
  version = "7.28.0-18108";
  arch = "amd64";
  src = requireFile {
    name = "${pname}_${version}_${arch}.deb";
    sha256 = "06whffp7q5p6b163kqkawc6x3a78s1x0rxp8km4bs80lfc090fh2";
    url = "file://./${pname}_${version}_${arch}.deb";
  };

  falcon-sensor = stdenv.mkDerivation {
    inherit version arch src;
    buildInputs = [ dpkg ];
    name = pname;
    sourceRoot = ".";

    unpackCmd = ''
      dpkg-deb -x "$src" .
    '';

    installPhase = ''
      cp -r ./ $out/
      realpath $out
    '';

    meta = with lib; {
      description = "Crowdstrike Falcon Sensor";
      homepage = "https://www.crowdstrike.com/";
      license = licenses.unfree;
      platforms = platforms.linux;
      maintainers = [ ];
    };
  };
in
buildFHSEnv {
  name = "fs-bash";
  targetPkgs = pkgs: [
    pkgs.libnl
    pkgs.openssl
    pkgs.zlib
  ];

  extraInstallCommands = ''
    ln -s ${falcon-sensor}/* $out/
  '';

  runScript = "bash";
}

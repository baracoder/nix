{ lib
, dpkg
, buildFHSEnv
, autoPatchelfHook
, glib
, alsa-lib
, cups
, libX11
, libXScrnSaver
, libXtst
, mesa
, nss
, gtk3
, libva
, libglvnd
, openssl
, udev
, libpulseaudio
, ffmpeg
, libXcursor
, libXi
, libXrandr
, makeWrapper
, makeDesktopItem
, copyDesktopItems
, fetchurl
, stdenv }:

stdenv.mkDerivation rec {
  pname = "drata-agent";
  version = "3.4.1";
  name = "${pname}-${version}";
  src = fetchurl {
    url = "https://cdn.drata.com/agent/dist/linux/drata-agent-3.4.1.deb";
    sha256 = "sha256-DVxsTAiDVNbGQZTvWZkvcu6UxB9oWTXh1AmqE7NLqBs=";
  };
  unpackCmd = "dpkg-deb -x $src ./${pname}-${version}";
  dontBuild = true;

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];

  desktopItems = [
    (makeDesktopItem {
      name = "${pname}";
      desktopName = "${pname}";
      exec = "${pname}";
      icon = "${pname}";
      categories = [ "Office" ];
    })
  ];

  buildInputs = [
    alsa-lib
    cups
    libX11
    libXScrnSaver
    libXtst
    mesa
    nss
    gtk3
    libva
  ];

  runtimeDependenciesPath = lib.makeLibraryPath [
    stdenv.cc.cc
    libglvnd
    openssl
    udev
    alsa-lib
    libpulseaudio
    libva
    ffmpeg
    libX11
    libXcursor
    libXi
    libXrandr
  ];

  postPatch = ''
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp -r opt $out/opt
    cp -r usr/share $out/share
    chmod +x "$out/opt/Drata Agent/drata-agent"
    ln -s "$out/opt/Drata Agent/drata-agent" $out/bin/drata-agent
    wrapProgram $out/bin/drata-agent \
      --prefix LD_LIBRARY_PATH : "$runtimeDependenciesPath"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Collects data for certification";
    homepage = "https://drata.com";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
    platforms = [ "x86_64-linux" ];
  };
}
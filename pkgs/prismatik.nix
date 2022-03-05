{ stdenv
, lib
, fetchFromGitHub
, qtbase
, qttools
, qmake
, wrapQtAppsHook
, qtserialport
, libpulseaudio
, which
, pkg-config
, libusb
, udev
, fftwFloat }:

stdenv.mkDerivation rec {
    pname = "prismatik";
    version = "5.11.2.29";

    src = fetchFromGitHub {
        owner = "psieg";
        repo = "Lightpack";
        rev = version;
        sha256 = "sha256-Fgumj5HqCQcX2dh061meb/Kt6TnmIpdu0KnNP1Tu3KE=";
    };

    sourceRoot = "source/Software";

    preBuild = ''
    sh update_locales.sh
    '';

    installPhase = ''
        install -Dm755 bin/Prismatik "$out/bin/prismatik"
        install -Dm644 dist_linux/package_template/etc/udev/rules.d/93-lightpack.rules "$out/share/udev/rules.d/93-lightpack.rules"
        install -Dm644 dist_linux/package_template/usr/share/icons/hicolor/22x22/apps/prismatik-on.png "$out/share/icons/hicolor/22x22/apps/prismatik-on.png"
        install -Dm644 dist_linux/package_template/usr/share/icons/Prismatik.png "$out/share/icons/Prismatik.png"
        install -Dm644 dist_linux/package_template/usr/share/applications/prismatik.desktop "$out/share/applications/prismatik.desktop"
        install -Dm644 dist_linux/package_template/usr/share/pixmaps/Prismatik.png "$out/share/pixmaps/Prismatik.png"
        install -Dm644 ../LICENSE "$out/share/licenses/prismatik/LICENSE"
    '';


    buildInputs = [ qtbase qtserialport libpulseaudio fftwFloat libusb udev ];
    nativeBuildInputs = [ wrapQtAppsHook qmake which pkg-config qttools ];
}
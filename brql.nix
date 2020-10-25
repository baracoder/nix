{ stdenv, fetchurl, cups, perl, glibc, ghostscript, which, makeWrapper, coreutils, gnused, gnugrep}:

let
  myPatchElf = file: with stdenv.lib; ''
    patchelf --set-interpreter \
      ${stdenv.glibc}/lib/ld-linux${optionalString stdenv.is64bit "-x86-64"}.so.2 \
      ${file}
  '';
in
stdenv.mkDerivation rec {

  name = "ql700pdrv-3.1.5-0";
  src = fetchurl {
    url = "https://download.brother.com/welcome/dlfp002192/${name}.i386.deb";
    sha256 = "sha256-/4AG/Dkb9FHOCsfRyF8Qy8LImG1arC4ksZTyC/Gjp8k=";
  };

  unpackPhase = ''
    ar x $src
    tar xfvz data.tar.gz
  '';

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ cups perl glibc ghostscript which ];

  dontBuild = true;

  patchPhase = ''
    INFDIR=opt/brother/PTouch/ql700/inf
    LPDDIR=opt/brother/PTouch/ql700/lpd
    # Setup max debug log by default.
    substituteInPlace $LPDDIR/filter_ql700 \
      --replace "BR_PRT_PATH =~" "BR_PRT_PATH = \"$out/opt/brother/PTouch/ql700\"; #" \
      --replace "PRINTER =~" "PRINTER = \"ql700\"; #"
    ${myPatchElf "$LPDDIR/x86_64/brpapertoollpr_ql700"}
    ${myPatchElf "$LPDDIR/x86_64/brprintconfpt1_ql700"}
    ${myPatchElf "$LPDDIR/x86_64/rastertobrpt1"}
    ${myPatchElf "$LPDDIR/x86_64/brpapertoolcups"}

    # move arch specific files
    mv $LPDDIR/x86_64/* $LPDDIR/
    rm -r $LPDDIR/i686  $LPDDIR/x86_64
      

    # from https://github.com/NixOS/nixpkgs/blob/84cf00f98031e93f389f1eb93c4a7374a33cc0a9/pkgs/misc/cups/drivers/brgenml1cupswrapper/default.nix
    WRAPPER=opt/brother/PTouch/ql700/cupswrapper/brother_lpdwrapper_ql700

    substituteInPlace $WRAPPER \
      --replace "PRINTER =~" "PRINTER = \"ql700\"; #" 

    # Fixing issue #1 and #2.
    substituteInPlace $WRAPPER \
      --replace "\`cp " "\`cp -p " \
      --replace "\$TEMPRC\`" "\$TEMPRC; chmod a+rw \$TEMPRC\`" \
      --replace "\`mv " "\`cp -p "

  '';

  installPhase = ''
    INFDIR=opt/brother/PTouch/ql700/inf
    LPDDIR=opt/brother/PTouch/ql700/lpd
    mkdir -p $out/$INFDIR
    cp -rp $INFDIR/* $out/$INFDIR
    mkdir -p $out/$LPDDIR
    cp -rp $LPDDIR/* $out/$LPDDIR
    wrapProgram $out/$LPDDIR/filter_ql700 \
      --prefix PATH ":" "${ghostscript}/bin" \
      --prefix PATH ":" "${which}/bin"


    # from https://github.com/NixOS/nixpkgs/blob/84cf00f98031e93f389f1eb93c4a7374a33cc0a9/pkgs/misc/cups/drivers/brgenml1cupswrapper/default.nix
    CUPSFILTER_DIR=$out/lib/cups/filter
    CUPSPPD_DIR=$out/share/cups/model
    CUPSWRAPPER_DIR=opt/brother/PTouch/ql700/cupswrapper

    WRAPPER=opt/brother/PTouch/ql700/cupswrapper/brother_lpdwrapper_ql700

    mkdir -p $out/$CUPSWRAPPER_DIR
    cp -rp $CUPSWRAPPER_DIR/* $out/$CUPSWRAPPER_DIR
    mkdir -p $CUPSFILTER_DIR
    # Fixing issue #4.
    makeWrapper \
      $out/$CUPSWRAPPER_DIR/brother_lpdwrapper_ql700 \
      $CUPSFILTER_DIR/brother_lpdwrapper_ql700 \
      --prefix PATH : ${coreutils}/bin \
      --prefix PATH : ${gnused}/bin \
      --prefix PATH : ${gnugrep}/bin
    mkdir -p $CUPSPPD_DIR
    ln -s $out/$CUPSWRAPPER_DIR/brother-ql700_printer_en.ppd $CUPSPPD_DIR
  '';

  dontPatchELF = true;


  meta = {
    description = "Brother BrGenML1 LPR driver";
    homepage = "http://www.brother.com";
    platforms = stdenv.lib.platforms.linux;
    license = stdenv.lib.licenses.unfreeRedistributable;
    maintainers = with stdenv.lib.maintainers; [ baracoder ];
  };
}

# see also https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=brother-ql700
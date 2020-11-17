{ stdenv, fetchurl, cups, perl, glibc, ghostscript, which, makeWrapper, coreutils, gnused, gnugrep, rpmextract, file, buildFHSUserEnv, writeScript, symlinkJoin }:

let
  myPatchElf = file: with stdenv.lib; ''
    patchelf --set-interpreter \
      ${stdenv.glibc}/lib/ld-linux${optionalString stdenv.is64bit "-x86-64"}.so.2 \
      ${file}
  '';
  driver = stdenv.mkDerivation rec {
  pname = "ql700pdrv";
  version = "3.1.5-0";
  src = fetchurl {
    url = "https://download.brother.com/welcome/dlfp002191/${pname}-${version}.i386.rpm";
    sha256 = "sha256-Ou/QLvTMNcPY7X2KmfesX1+kTDV0R5xF7NRDs2MCkEA=";
  };

  unpackPhase = ''
    rpmextract $src
  '';

  nativeBuildInputs = [ makeWrapper rpmextract ];
  buildInputs = [ cups perl glibc ghostscript which stdenv ];

  dontBuild = true;

  patchPhase = ''
    BASEDIR=opt/brother/PTouch/ql700
    INFDIR=$BASEDIR/inf
    LPDDIR=$BASEDIR/lpd

    # move arch specific files
    mv $LPDDIR/x86_64/* $LPDDIR/
    rm -r $LPDDIR/i686  $LPDDIR/x86_64

    ${myPatchElf "$LPDDIR/brpapertoollpr_ql700"}
    ${myPatchElf "$LPDDIR/brprintconfpt1_ql700"}
    ${myPatchElf "$LPDDIR/rastertobrpt1"}
    ${myPatchElf "$LPDDIR/brpapertoolcups"}
    #mv $LPDDIR/brprintconfpt1_ql700 $LPDDIR/brprintconfpt1_ql700_orig
                                                 #/opt/brother/PTouch/%s/inf/br%sfunc
    #bbe -e "s#/opt/brother/PTouch/%s/inf/br%sfunc#/brql700func\0                      #" -o $LPDDIR/brprintconfpt1_ql700 $LPDDIR/brprintconfpt1_ql700_orig 
    #rm $LPDDIR/brprintconfpt1_ql700_orig
    #chmod +x $LPDDIR/brprintconfpt1_ql700


    substituteInPlace $LPDDIR/filter_ql700 \
      --replace "BR_PRT_PATH = " "BR_PRT_PATH = \$ENV{BASEPATH}; #" \
      --replace "PRINTER =~" "PRINTER = \"ql700\"; #" \
      --replace "/usr/bin/pdf2ps" "pdf2ps"

    WRAPPER=$BASEDIR/cupswrapper/brother_lpdwrapper_ql700

    substituteInPlace $WRAPPER \
      --replace "PRINTER =~" "PRINTER = \"ql700\"; #"   \
      --replace "DEBUG=0" "DEBUG=1"   \
      --replace "basedir =~ " "basedir = \$ENV{BASEPATH}; #"   \
      --replace "\`cp " "\`cp -p "

  '';

  installPhase = ''
    INFDIR=opt/brother/PTouch/ql700/inf
    LPDDIR=opt/brother/PTouch/ql700/lpd
    CUPSFILTER_DIR=$out/lib/cups/filter
    CUPSPPD_DIR=$out/share/cups/model
    CUPSWRAPPER_DIR=opt/brother/PTouch/ql700/cupswrapper
    WRAPPER=$CUPSWRAPPER_DIR/brother_lpdwrapper_ql700



    mkdir -p $out/$INFDIR
    cp -rp $INFDIR/* $out/$INFDIR
    mkdir -p $out/$LPDDIR
    cp -rp $LPDDIR/* $out/$LPDDIR

    mkdir -p $out/$CUPSWRAPPER_DIR
    cp -rp $CUPSWRAPPER_DIR/* $out/$CUPSWRAPPER_DIR
    mkdir -p $CUPSFILTER_DIR


    mkdir -p $CUPSPPD_DIR
    ln -s $out/$CUPSWRAPPER_DIR/brother_ql700_printer_en.ppd $CUPSPPD_DIR
  '';

  dontPatchELF = false;

  meta = {
    description = "Brother BrGenML1 LPR driver";
    homepage = "http://www.brother.com";
    platforms = stdenv.lib.platforms.linux;
    license = stdenv.lib.licenses.unfreeRedistributable;
    maintainers = with stdenv.lib.maintainers; [ baracoder ];
  };
};
fhs = buildFHSUserEnv {
  name = "ql700pdrv-filter-env";
  targetPkgs = pkgs: [ driver ];
  runScript = ''
  ${driver}/opt/brother/PTouch/ql700/lpd/filter_ql700
  '';
};
in
symlinkJoin {
  name = "ql700-joined";
  paths = [ driver fhs ];
  buildInputs = [ makeWrapper ];
  postBuild = ''
    #f=$out/lib/cups/filter/brother_lpdwrapper_ql700
    #cp --remove-destination $(${coreutils}/bin/readlink -e $f) $f
    #f=$out/opt/brother/PTouch/ql700/lpd/filter_ql700
    #cp --remove-destination $(${coreutils}/bin/readlink -e $f) $f
    cp --remove-destination $out/bin/ql700pdrv-filter-env $out/opt/brother/PTouch/ql700/lpd/filter_ql700


    LPDDIR=opt/brother/PTouch/ql700/lpd
    CUPSWRAPPER_DIR=opt/brother/PTouch/ql700/cupswrapper
    CUPSFILTER_DIR=lib/cups/filter
    mkdir -p $out/$CUPSFILTER_DIR

    echo bla > $out/$CUPSFILTER_DIR/brother_lpdwrapper_ql700_test
    makeWrapper \
      ${driver}/$CUPSWRAPPER_DIR/brother_lpdwrapper_ql700 \
      $out/$CUPSFILTER_DIR/brother_lpdwrapper_ql700 \
      --set BASEPATH "$out/opt/brother/PTouch/ql700" \
      --prefix PATH : ${coreutils}/bin \
      --prefix PATH : ${gnused}/bin \
      --prefix PATH : ${file}/bin \
      --prefix PATH : ${gnugrep}/bin

    wrapProgram $out/$LPDDIR/filter_ql700 \
      --set LPD_DEBUG 1 \
      --set BASEPATH "$out/opt/brother/PTouch/ql700" \
      --prefix PATH ":" "${ghostscript}/bin" \
      --prefix PATH ":" "${coreutils}/bin" \
      --prefix PATH ":" "${which}/bin"

  '';
}
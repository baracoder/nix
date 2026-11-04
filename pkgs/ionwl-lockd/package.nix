{
  lib,
  stdenvNoCC,
  makeWrapper,
  python3,
  glib,
  gtklock,
}:

let
  python = python3.withPackages (ps: [ ps.pygobject3 ]);
in
stdenvNoCC.mkDerivation {
  pname = "ionwl-lockd";
  version = "0.1.0";

  dontUnpack = true;
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    install -Dm644 ${./ionwl-lockd.py} $out/share/ionwl-lockd/ionwl-lockd.py
    makeWrapper ${lib.getExe python} $out/bin/ionwl-lockd \
      --add-flags $out/share/ionwl-lockd/ionwl-lockd.py \
      --prefix GI_TYPELIB_PATH : ${glib.out}/lib/girepository-1.0 \
      --prefix PATH : ${lib.makeBinPath [ gtklock ]}
  '';

  meta = {
    description = "Run a screen locker on logind lock requests and before sleep";
    mainProgram = "ionwl-lockd";
    platforms = lib.platforms.linux;
  };
}

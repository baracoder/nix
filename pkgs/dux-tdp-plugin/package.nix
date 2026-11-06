{
  lib,
  stdenvNoCC,
  runtimeShell,
  glib,
  powerstation-tdp,
}:

# dux-shell (DMS) plugin: TDP slider, presets and boost for the bar and the
# Control Center, the counterpart of gnome-extension-tdp-baracoder. The output
# is the plugin directory itself; install it with
# `programs.dux-shell.plugins.<Name>.src`, which links it to
# /etc/xdg/quickshell/dms-plugins/<Name>.
stdenvNoCC.mkDerivation {
  pname = "dux-tdp-plugin";
  version = "1.0.0";

  src = ./src;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r . $out
    substituteInPlace $out/TdpWidget.qml \
      --replace-fail '@shell@' '${runtimeShell}' \
      --replace-fail '@powerstationTdp@' '${lib.getExe powerstation-tdp}' \
      --replace-fail '@gdbus@' '${lib.getExe' glib.bin "gdbus"}'
    runHook postInstall
  '';

  meta = {
    description = "dux-shell plugin to set the APU power limit through PowerStation";
    platforms = lib.platforms.linux;
  };
}

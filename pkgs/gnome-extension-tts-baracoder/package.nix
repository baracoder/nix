{
  pkgs,
  lib,
  stdenv,
  fetchurl,
  linkFarm,
  writeShellApplication,
  nixosTests,
}:
let

  pname = "gnome-shell-extension-baracoder-tts";
  version = "git";
  uuid = "tts@baracoder";

  # piper looks for <model>.onnx.json next to the model, so keep both together.
  piperVoice =
    {
      path,
      name,
      onnxHash,
      jsonHash,
    }:
    let
      base = "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/${path}/${name}";
    in
    "${
      linkFarm "piper-voice-${name}" {
        "${name}.onnx" = fetchurl {
          url = "${base}.onnx";
          hash = onnxHash;
        };
        "${name}.onnx.json" = fetchurl {
          url = "${base}.onnx.json";
          hash = jsonHash;
        };
      }
    }/${name}.onnx";

  voiceEn = piperVoice {
    path = "en/en_GB/jenny_dioco/medium";
    name = "en_GB-jenny_dioco-medium";
    onnxHash = "sha256-RpxjDSCeE53TkqZr9KveSrhjkKAmnB5HtOXXzoFSawE=";
    jsonHash = "sha256-qaepOjF8mjy2Vj436wV9+e8JwGGIqKQ0Gw/LWMulTdQ=";
  };

  voiceDe = piperVoice {
    path = "de/de_DE/thorsten/high";
    name = "de_DE-thorsten-high";
    onnxHash = "sha256-nfHEPGEUnvmznmGOK4YfvkHh/OqTkLLaxi6HYVc+pPE=";
    jsonHash = "sha256-bec0RE5MP54zt+vidG28GbcehfYT55xlrPYjIAuZp2o=";
  };

  script = writeShellApplication {
    name = "tts-baracoder";
    runtimeInputs = with pkgs; [
      jq
      piper-tts
      pipewire
      python3Packages.py3langid
      wl-clipboard
    ];
    text = ''
      voice_en=${voiceEn}
      voice_de=${voiceDe}
    ''
    + builtins.readFile ./tts-baracoder;
  };
in
stdenv.mkDerivation {
  inherit pname version;
  src = ./src;
  nativeBuildInputs = with pkgs; [ buildPackages.glib ];
  postPatch = ''
    substituteInPlace extension.js \
      --replace-fail '@ttsCommand@' '${lib.getExe script}'
  '';
  buildPhase = ''
    runHook preBuild
    if [ -d schemas ]; then
      glib-compile-schemas --strict schemas
    fi
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/gnome-shell/extensions/ $out/bin
    cp -r -T . $out/share/gnome-shell/extensions/tts@baracoder
    ln -s ${lib.getExe script} $out/bin/tts-baracoder
    runHook postInstall
  '';
  passthru = {
    extensionPortalSlug = pname;
    extensionUuid = uuid;
    inherit script;

    tests = {
      gnome-extensions = nixosTests.gnome-extensions;
    };
  };
}

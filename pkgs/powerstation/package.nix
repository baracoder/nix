{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  udev,
  pciutils,
  cmake,
}:

# Local bump of nixpkgs' powerstation (0.8.1 at the time of writing).
#
# 0.8.1 decides whether a GPU is integrated from its PCI class code alone:
# 030000 (VGA compatible controller) is integrated, 038000 (display controller)
# is dedicated, and only integrated cards get a TDP interface. hal's Strix
# iGPU enumerates as 038000, so PowerStation exposed no TDP control at all.
# 0.8.3 asks the amdgpu driver whether the card is an APU instead.
#
# Drop this once nixpkgs ships >= 0.8.3.
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "powerstation";
  version = "0.8.3";

  src = fetchFromGitHub {
    owner = "ShadowBlip";
    repo = "PowerStation";
    tag = "v${finalAttrs.version}";
    hash = "sha256-/8NpEPHGqqx8Xkibfx8aZUzPfCXBC2JgLWaHmGuG8FU=";
  };

  cargoHash = "sha256-qEOcXAHgYw/5HEPFHjILYcTuxVXjBMegiAajEGTUPSM=";

  nativeBuildInputs = [
    cmake
    pkg-config
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    udev
    pciutils
  ];

  postInstall = ''
    cp -r rootfs/usr/* $out/

    # PowerStation's APU database matches this CPU and reports the silicon's
    # 15-54 W range, far past what the GPD Win Max 2 chassis can cool. A DMI
    # override keyed on the product name beats the CPU match and has the
    # highest merge priority, so PowerStation reports the chassis limits itself
    # and every client -- the quick settings slider included -- gets them for
    # free. The numbers are hhd's device limits for this exact model
    # (adjustor's DEV_PARAMS_28W: stapm 4-28 W, fast PPT 4 W over sustained).
    cat >> $out/share/powerstation/platform/dmi_overrides_apu_database.toml <<'TOML'

    [[models]]
    model_name = "G1619-05"
    min_tdp = 4.0
    max_tdp = 28.0
    max_boost = 4.0
    TOML
  '';

  meta = {
    description = "Open source TDP control and performance daemon with DBus interface";
    homepage = "https://github.com/ShadowBlip/PowerStation";
    license = lib.licenses.gpl3Plus;
    changelog = "https://github.com/ShadowBlip/PowerStation/releases/tag/v${finalAttrs.version}";
    maintainers = with lib.maintainers; [ shadowapex ];
    mainProgram = "powerstation";
  };
})

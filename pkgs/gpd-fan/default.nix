{stdenv, fetchFromGitHub, lib, kernel}:

stdenv.mkDerivation {
  pname = "gpd-fan-driver";
  version = "0-unstable";

  src = fetchFromGitHub {
    owner = "antheas";
    repo = "gpd-fan-driver";
    rev = "hx370";
    hash = "sha256-Zt1z9I/wdJzovcyBujBJ9Vm5TU9L09Q7tW2eLTJz6E8=";
  };

  hardeningDisable = [ "pic" ];

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = [
    "KERNEL_SRC=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];

  installPhase = ''
    runHook preInstall

    install *.ko -Dm444 -t $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/gpdfan

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://github.com/Cryolitia/gpd-fan-driver/";
    description = "A kernel driver for the GPD devices fan";
    license = with licenses; [ gpl2Plus ];
    maintainers = with maintainers; [ Cryolitia ];
    platforms = [ "x86_64-linux" ];
  };
}
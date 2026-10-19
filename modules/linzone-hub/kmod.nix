{
  lib,
  stdenv,
  kernel,
  kernelModuleMakeFlags,
  linzone-hub,
}:

# Lives outside pkgs/ because it needs a `kernel`, which the overlay's
# packagesFromDirectoryRecursive cannot supply; build it through
# boot.kernelPackages.callPackage instead.
stdenv.mkDerivation {
  pname = "hid-inzone-battery";
  version = "${linzone-hub.version}-${kernel.version}";

  inherit (linzone-hub) src;
  sourceRoot = "${linzone-hub.src.name}/kernel/hid-inzone-battery-dkms";

  nativeBuildInputs = kernel.moduleBuildDependencies;

  # The upstream Makefile forces CC=clang LLVM=1, which only matches a
  # clang-built kernel. Drive kbuild directly with the kernel's own toolchain.
  makeFlags = kernelModuleMakeFlags ++ [
    "-C"
    "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "M=$(PWD)"
  ];
  buildFlags = [ "modules" ];

  installPhase = ''
    runHook preInstall
    install -Dm444 hid_inzone_battery.ko \
      $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/hid/hid_inzone_battery.ko
    runHook postInstall
  '';

  meta = {
    description = "Sony INZONE HID battery power_supply driver";
    homepage = "https://github.com/patyhank/linzone-hub";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
  };
}

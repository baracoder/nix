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
    "INSTALL_MOD_PATH=${placeholder "out"}"
    "INSTALL_MOD_DIR=kernel/drivers/hid"
    "DEPMOD=true"
  ];
  buildFlags = [ "modules" ];
  # Install through kbuild so the module gets compressed and its .ko.cer is
  # generated, which aggregateModules expects (nixpkgs#575192).
  installTargets = [ "modules_install" ];

  meta = {
    description = "Sony INZONE HID battery power_supply driver";
    homepage = "https://github.com/patyhank/linzone-hub";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
  };
}

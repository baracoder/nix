{
  lib,
  stdenv,
  kernel,
  kernelModuleMakeFlags,
  vds,
}:

# Lives outside pkgs/ because it needs a `kernel`; build it through
# boot.kernelPackages.callPackage (see modules/linzone-hub/kmod.nix).
stdenv.mkDerivation {
  pname = "vds-hcd";
  version = "${vds.version}-${kernel.version}";

  inherit (vds) src;
  sourceRoot = "${vds.src.name}/module";

  nativeBuildInputs = kernel.moduleBuildDependencies;

  # Drive kbuild directly; upstream's Makefile wraps it in DKMS and git.
  makeFlags = kernelModuleMakeFlags ++ [
    "-C"
    "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "M=$(PWD)"
    "VDS_VERSION=${vds.version}"
    "INSTALL_MOD_PATH=${placeholder "out"}"
    "INSTALL_MOD_DIR=extra"
    "DEPMOD=true"
  ];
  buildFlags = [ "modules" ];
  installTargets = [ "modules_install" ];

  meta = {
    description = "vDS virtual USB host controller for DualSense controllers";
    inherit (vds.meta) homepage license platforms;
  };
}

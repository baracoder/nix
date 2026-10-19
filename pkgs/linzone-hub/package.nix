{
  lib,
  buildGoModule,
  buildNpmPackage,
  fetchFromGitHub,
  pkg-config,
  wrapGAppsHook4,
  gtk4,
  webkitgtk_6_0,
  hidapi,
  libusb1,
  udev,
}:

let
  version = "0.1.0-4";

  src = fetchFromGitHub {
    owner = "patyhank";
    repo = "linzone-hub";
    tag = "v${version}";
    hash = "sha256-+XHLTM3L2lxRRFcAQGHBuzm8aj/mweGMgjqdPApyJkM=";
  };

  # The Wails bindings are committed, so the frontend builds without wails3.
  frontend = buildNpmPackage {
    pname = "linzone-hub-frontend";
    inherit version src;
    sourceRoot = "${src.name}/frontend";
    npmDepsHash = "sha256-4DC3AbHaMW63IZq8xy5nxElM61nYnFFUtD7SXnouWtQ=";
    installPhase = ''
      runHook preInstall
      cp -r dist $out
      runHook postInstall
    '';
  };
in
buildGoModule {
  pname = "linzone-hub";
  inherit version src;

  # `go mod vendor` trips over a Windows-only embed in wails/webview2.
  proxyVendor = true;
  vendorHash = "sha256-rYtFXV66wCGwqEFsB8uaIepbhVQMsPTnrjEJ8ge1ptI=";

  # main.go embeds frontend/dist.
  preBuild = ''
    cp -r ${frontend} frontend/dist
  '';

  subPackages = [
    "."
    "cmd/inzone-cli"
  ];

  tags = [ "production" ];
  ldflags = [
    "-s"
    "-w"
  ];

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook4
  ];

  buildInputs = [
    gtk4
    webkitgtk_6_0
    hidapi
    libusb1
    udev
  ];

  # udev has no := for ENV. These lines follow the generic "headset"
  # assignment, so a plain = already overrides it.
  postPatch = ''
    substituteInPlace kernel/hid-inzone-battery-dkms/99-inzone-battery.rules \
      --replace-fail 'ENV{UPOWER_BATTERY_TYPE}:=' 'ENV{UPOWER_BATTERY_TYPE}='
  '';

  postInstall = ''
    install -Dm644 packaging/linux/dev.patyhank.linzonehub.desktop \
      $out/share/applications/dev.patyhank.linzonehub.desktop
    install -Dm644 frontend/public/inzone-assets/resources/app_notify_icon.png \
      $out/share/icons/hicolor/64x64/apps/linzone-hub.png
    install -Dm644 kernel/hid-inzone-battery-dkms/99-inzone-battery.rules \
      $out/lib/udev/rules.d/99-inzone-battery.rules
  '';

  passthru = { inherit frontend; };

  meta = {
    description = "Linux GUI controller for Sony INZONE devices";
    homepage = "https://github.com/patyhank/linzone-hub";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "linzone-hub";
  };
}

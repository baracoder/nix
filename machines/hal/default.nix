{
  pkgs,
  lib,
  ...
}:
let
  linuxPackages = pkgs.linuxPackages_zen;
in
{
  imports = [
    ./audio.nix
    ./filesystems.nix
  ];

  nixpkgs.overlays = [
    # (final: prev: {
    #   gdm = prev.gdm.overrideAttrs (a: {
    #     patches = a.patches ++ [
    #       (final.fetchpatch {
    #         url = "https://gitlab.gnome.org/GNOME/gdm/-/merge_requests/343.diff";
    #         hash = "sha256-48QhxuBo9QOVhy9R1yfgT0ggeOaDqYrLz3UNKhDEsh0=";
    #       })
    #     ];
    #   });
    # })
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.timeout = 0;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = linuxPackages;
  boot.extraModulePackages = with linuxPackages; [
    acpi_call
    ryzen-smu
  ];
  boot.initrd.prepend = [ "${./dsdt/acpi_override}" ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.initrd.availableKernelModules = [
    "amdgpu"
    "xhci_pci"
    "ehci_pci"
    "ahci"
    "usbhid"
    "sd_mod"
    "nvme"
    "nvme_core"
  ];
  boot.kernelModules = [
    "btrfs"
    "acpi_call"
    "iwlwifi"
    "gpd_fan"
    "ryzen_smu"
  ];
  boot.plymouth.enable = true;
  boot.plymouth.extraConfig = ''
    DeviceScale=2
  '';

  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.network.wait-online.enable = false;

  boot.blacklistedKernelModules = [
    "nouveau"
    "bmi160_spi"
    "bmi160_i2c"
    "bmi160_core"
  ];
  boot.extraModprobeConfig = ''
    options bluetooth disable_ertm=1
    # power_scheme=1 (CAM) disables wifi power save. The default (2, balanced)
    # lets the card doze between beacons, which delays ACKs; APs running a
    # low-ack watchdog read that as an unresponsive client and deauth with
    # reason 34. Note NetworkManager's wifi.powersave does not apply under the
    # iwd backend, so this modprobe option is the only lever that works here.
    options iwlmvm power_scheme=1
  '';

  systemd.generators.systemd-gpt-auto-generator = "/dev/null";

  hardware.cpu.amd.updateMicrocode = true;
  hardware.bluetooth.enable = true;
  hardware.steam-hardware.enable = true;

  services.powerstation.enable = true;
  systemd.services.powerstation.environment.XDG_DATA_DIRS = lib.mkForce (
    lib.concatStringsSep ":" [
      "${pkgs.hwdata}/share"
      "/run/current-system/sw/share"
    ]
  );
  services.inputplumber.enable = true;
  environment.etc."inputplumber/devices.d/55-gpd-winmax2-2025.yaml".source =
    ./inputplumber-gpd-winmax2-2025.yaml;
  environment.etc."inputplumber/capability_maps.d/55-gpd-winmax2-2025.yaml".source =
    ./inputplumber-capability-map-gpd-winmax2-2025.yaml;

  # The back paddles live in the controller's firmware, not in any kernel or
  # InputPlumber setting, so they survive a reinstall and have to be programmed
  # over HID. Two things matter here:
  #
  #   * l41/r41 pin the paddles to F20/F21, which is what the gpd_winmax2_2025
  #     capability map above translates into gamepad paddle buttons.
  #   * l4delay4/r4delay4 is the pause after the macro ends, i.e. the interval
  #     at which a held paddle re-fires. It had been dropped to 25ms, so the
  #     paddles repeated ~40x/second; 300 is the GPD factory value.
  systemd.services.gpd-paddle-config = {
    description = "Program GPD Win Max 2 back paddle firmware";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script =
      let
        # gpdconfig rewrites the device's flash on every invocation, without
        # checking whether anything actually changed, so compare first.
        settings = [
          "l41=F20"
          "l42=NONE"
          "l43=NONE"
          "l44=NONE"
          "r41=F21"
          "r42=NONE"
          "r43=NONE"
          "r44=NONE"
          "l4delay1=100"
          "l4delay2=100"
          "l4delay3=100"
          "l4delay4=300"
          "r4delay1=100"
          "r4delay2=100"
          "r4delay3=100"
          "r4delay4=300"
        ];
      in
      ''
        # The controller sits on USB and may not have enumerated yet.
        for _ in $(seq 30); do
          ${pkgs.pywincontrols}/bin/gpdconfig -v > /run/gpd-paddle-config.current 2>/dev/null && break
          sleep 1
        done
        if [ ! -s /run/gpd-paddle-config.current ]; then
          echo "GPD controller did not appear; leaving paddle config alone" >&2
          exit 0
        fi

        needed=""
        for kv in ${lib.escapeShellArgs settings}; do
          grep -qxF "$kv" /run/gpd-paddle-config.current || needed="$needed $kv"
        done

        if [ -z "$needed" ]; then
          echo "Paddle firmware already as configured; not rewriting flash"
          exit 0
        fi

        echo "Updating paddle firmware:$needed"
        # shellcheck disable=SC2086
        ${pkgs.pywincontrols}/bin/gpdconfig ${lib.escapeShellArgs settings}
      '';
  };

  systemd.packages = [ pkgs.steamos-manager ];
  systemd.services.steamos-manager = {
    overrideStrategy = "asDropin";
    wantedBy = [ "multi-user.target" ];
    after = [ "powerstation.service" ];
    wants = [ "powerstation.service" ];
  };
  systemd.user.services.steamos-manager = {
    overrideStrategy = "asDropin";
    wantedBy = [ "graphical-session.target" ];
  };

  # Auto-adjust TDP based on power state at startup
  systemd.services.tdp-auto-adjust = {
    wantedBy = [ "multi-user.target" ];
    after = [ "powerstation.service" ];
    requires = [ "powerstation.service" ];
    path = [ pkgs.powerstation-tdp ];
    script = ''
      until [ -e "/sys/class/power_supply/ADP1/online" ]; do
        sleep 1
      done
      powerstation-tdp wait 45
      sleep 5
      # Check if AC adapter is online (1=AC, 0=battery)
      if grep -q 1 /sys/class/power_supply/ADP1/online; then
        powerstation-tdp set 22
      else
        powerstation-tdp set 14
      fi
      # No headroom above the sustained limit, matching hhd's unchecked
      # "Boost". Set after the TDP: `set` preserves whatever boost it finds.
      powerstation-tdp boost 0
    '';
    serviceConfig.Type = "oneshot";
    serviceConfig.TimeoutSec = 120;
  };

  services.resolved.enable = true;

  services.power-profiles-daemon.enable = true; # Platform profiles; TDP itself is handled by powerstation
  powerManagement.cpuFreqGovernor = "ondemand";

  #virtualisation.waydroid.enable = true;
  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.hooks.qemu.win10-gpu = ./libvirt-gpu-passthrough-hook.sh;
  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
    storageDriver = "overlay2";
    listenOptions = [
      "/run/docker.sock"
      "0.0.0.0:2375"
    ];

  };

  services.ollama = {
    enable = true;
    package = pkgs.ollama-vulkan;
  };
  systemd.services.ollama.environment = {
    OLLAMA_SCHED_SPREAD = "1";
    OLLAMA_IGPU_ENABLE = "1";
  };

  services.logind.settings.Login.HandlePowerKey = "suspend";

  networking.hostName = "hal";
  networking.firewall.enable = true;
  networking.firewall.logRefusedConnections = false;
  services.fprintd.enable = false;
  #systemd.services.fprintd = {
  #  conflicts = [ "sleep.target" "suspend.target" "hybernante.target" ];
  #};

  system.stateVersion = "19.09";

  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";

  boot.kernelParams = [
    "quiet"
    "nouveau.modeset=0"
    # allow PCI device pass through
    "amd_iommu=on"
    "iommu=pt"
    "acpi_enforce_resources=lax"
    "bluetooth.disable_ertm=1" # bluetooth gamepad compatibility
    "pcie_hp=1"
    "pci=realloc"
  ];

  services.xserver.videoDrivers = [ "amdgpu" ];
  programs.xwayland.enable = true;
  programs.coolercontrol.enable = true;
  programs.ausweisapp = {
    enable = true;
    openFirewall = true;
  };
  systemd.services.coolercontrold.preStart = "${pkgs.coreutils}/bin/sleep 15";

  nix.settings.max-jobs = lib.mkDefault 8;

  hardware.graphics = {
    extraPackages = with pkgs; [
      libva-vdpau-driver
      libvdpau-va-gl
    ];
    extraPackages32 = with pkgs; [
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  # Workaround for LG Ultrawide stuttering on playback resume.
  services.pipewire.wireplumber.extraConfig = {
    "hdmi-screen" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            {
              "node.name" = "~alsa_output.*hdmi*";
            }
          ];
          actions = {
            update-props = {
              "session.suspend-timeout-seconds" = 0;
              "node.always-process" = true;
            };
          };
        }
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    amd-debug-tools
    amdgpu_top
    audacity
    clonehero
    easyeffects
    discord
    ffmpeg
    gearlever
    pkgs.python3Packages.huggingface-hub
    mediathekview
    vulkan-tools
    libva-utils
    orca-slicer
    looking-glass-client
    virtiofsd
    ptouch-print
    nebula
    newelle
    pywincontrols
    nh
    fprintd
    vial
    vivaldi
    gnome-extension-tdp-baracoder
    gnome-extension-tdp-control
    powerstation-tdp
    # steamosctl, plus the D-Bus policy and interface files
    steamos-manager
  ];

  programs.appimage.enable = true;
  programs.appimage.binfmt = true;

  hardware.sensor.iio.enable = true;
  hardware.enableRedistributableFirmware = true;

  services.udev.extraRules = ''
    # Avoid wake-up from i2c devices on GPD Win Max 2
    # SUBSYSTEM=="i2c", KERNEL=="i2c-PNP0C50:00", ATTR{power/wakeup}="disabled"
    SUBSYSTEM=="i2c", KERNEL=="i2c-GXTP7385:00", ATTR{power/wakeup}="disabled"

    # Disable fprint scanner
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2541", ATTRS{idProduct}=="9711", ATTR{remove}="1"

    # x52 joystick
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="06a3", ATTRS{idProduct}=="0762", MODE="0666"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="06a3", ATTRS{idProduct}=="0255", MODE="0666"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="06a3", ATTRS{idProduct}=="075c", MODE="0666"

    # relabsd space mouse
    SUBSYSTEM=="input", ATTRS{name}=="relabsd:*", ENV{ID_INPUT_MOUSE}="0", ENV{ID_INPUT_JOYSTICK}="1", ENV{ID_CLASS}="joystick", MODE="0666"

    # Borther P-Touch printers
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="04f9", MODE="0666"

    # preferred GPU for gnome
    ATTRS{vendor}=="0x1002", TAG+="mutter-device-preferred-primary"
    ATTRS{vendor}=="0x10de", TAG+="mutter-device-ignore"
  '';
  services.udev.packages = [
    pkgs.vial
  ];
  services.displayManager.defaultSession = lib.mkForce "gnome";

  systemd.tmpfiles.settings."10-looking-glass" = {
    "/dev/shm/looking-glass".f = {
      group = "libvirtd";
      user = "bara";
      mode = "0660";
    };
  };

  # disable touch on lid closed
  systemd.services.lid-touch-toggle = {
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [
      gawk
      dbus
    ];
    script = builtins.readFile ./toggle-touch-on-lid.sh;
  };

  systemd.services.systemd-vconsole-setup.unitConfig.After = "local-fs.target";

  systemd.services.NetworkManager-wait-online.enable = false;

  networking.networkmanager.dispatcherScripts = [
    {
      source =
        pkgs.writers.writeBash "70-toggle-wifi-on-ethernet"
          {
            makeWrapperArgs = [
              "--prefix"
              "PATH"
              ":"
              "${lib.makeBinPath [ pkgs.networkmanager ]}"
            ];
          }
          ''
            export LC_ALL=C

            # Only real ethernet counts. Docker veths, bridges and the netbird
            # tunnel also report type "ethernet" and would otherwise kill wifi
            # whenever a container comes up.
            ethernet_connected() {
                local dev type state
                while IFS=: read -r dev type state; do
                    case "$dev" in
                        veth* | docker* | br-* | virbr* | nb-* | tun* | tap*) continue ;;
                    esac
                    if [ "$type" = ethernet ] && [ "$state" = connected ]; then
                        return 0
                    fi
                done <<< "$(nmcli -t -f DEVICE,TYPE,STATE device status)"
                return 1
            }

            set_wifi() {
                # Never toggle the radio when it is already in the wanted state:
                # an off/on cycle is a hard disconnect. "nmcli radio wifi" takes
                # on/off but reports back enabled/disabled.
                local want
                case "$1" in
                    on) want=enabled ;;
                    off) want=disabled ;;
                esac
                [ "$(nmcli -t radio wifi)" = "$want" ] || nmcli radio wifi "$1"
            }

            # No connectivity-change: it fires while wifi is dropping, and
            # cycling the radio then only lengthens the outage.
            case "$2" in
              up|down)
                  if ethernet_connected; then
                      set_wifi off
                  else
                      set_wifi on
                  fi
                  ;;
            esac
          '';
    }
  ];

  services.netbird.clients.gr = {
    environment.NB_MANAGEMENT_URL = "https://net.gr.zebar.de";

    port = 51821;
    ui.enable = true;
    openFirewall = true;
    openInternalFirewall = true;

  };

}

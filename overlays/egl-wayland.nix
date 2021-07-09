self: super:
{
    egl-wayland = super.egl-wayland.overrideAttrs (a: rec {
        version = "1.1.7";
        src = self.fetchFromGitHub {
            sha256 = "sha256-pqpJ6Uo50BouBU0wGaL21VH5rDiVHKAvJtfzL0YInXU=";
            rev = version;
            owner = "Nvidia";
            repo = "egl-wayland";
        };
    });
    xwayland = super.xwayland.overrideAttrs (a: rec {
        pname = a.pname;
        version = "21.1.2";
        mesonFlags = a.mesonFlags ++ [
            "-Dxwayland_eglstream=true"
            "-Ddri3=true" 
            "-Dglamor=true"
        ];

        src = super.fetchurl {
            url = "mirror://xorg/individual/xserver/${pname}-${version}.tar.xz";
            sha256 = "sha256-uBy91a1guLetjD7MfsKijJvwIUSGcHNc67UB8Ivr0Ys=";
        };
    });

}
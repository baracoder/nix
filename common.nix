# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
{
  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    daemonIONiceLevel = 5;
    daemonNiceLevel = 5;
    gc = {
      automatic = true;
      dates = "13:00";
      options = "--delete-older-than 30d";
      #binaryCaches = [
      #  "https://cache.nixos.org/"
      #  "https://hie-nix.cachix.org"
      #];
      #binaryCachePublicKeys = [ 
      #  "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs="
      #  "hie-nix.cachix.org-1:EjBSHzF6VmDnzqlldGXbi0RM3HdjfTU3yDRi9Pd0jTY="
      #];
    };
  };
  nixpkgs.config.allowUnfree = true;

  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;

  hardware.ksm.enable = true;


  console.font = "Lat2-Terminus16";
  console.keyMap = "us";
  i18n.defaultLocale = "en_US.UTF-8";

  time.timeZone = "Europe/Berlin";



  fonts = {
    enableDefaultFonts = true;
    enableFontDir = true;
    enableGhostscriptFonts = true;
    fontconfig = {
      enable = true;
      allowBitmaps = true;
    };
    fonts = with pkgs; [
      terminus_font
      terminus_font_ttf
      corefonts
      inconsolata
      ubuntu_font_family
      unifont
      twemoji-color-font
    ];
  };

  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
    package = pkgs.pulseaudioFull;
  };

  services = {
    flatpak.enable = true;
    avahi = {
      enable = true;
      nssmdns = true;
    };
    openssh.enable = true;
    openssh.forwardX11 = true;
    udisks2.enable = true;
    printing.enable = true;
    xserver = 
    let xkbVariant = "altgr-intl"; # no dead keys
        xkbOptions = "eurosign:e,compose:menu,lv3:caps_switch";
    in {
      inherit xkbVariant xkbOptions;

      enable = true;
      layout = "us";
      exportConfiguration = true;

      displayManager = {
        gdm = {
          enable = true;
          nvidiaWayland = false;
        };
        autoLogin = {
          enable = false;
          user = "bara";
        };
      };
      desktopManager.gnome3 = {
        enable = true;
        extraGSettingsOverrides = ''
          [org.gnome.desktop.input-sources]
          sources=[('xkb', '${xkbVariant}')]
          xkb-options=['${xkbOptions}']
        '';
      };
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.bara = {
    isNormalUser = true;
    uid = 1000;
    group = "bara";
    extraGroups = [ "dialout" "avahi" "users" "video" "wheel" "adm" "audio" "docker" "input" "vboxusers" "adbusers" "libvirtd" ];
    createHome = true;
    shell = pkgs.zsh;
  };
  users.extraGroups.bara.gid = 1000;


  services.udev.packages = with pkgs; [ 
    openhantek6022
  ];
  environment.shells = [ pkgs.bashInteractive pkgs.zsh ];

  environment.systemPackages = with pkgs; [
    aspell
    aspellDicts.de
    aspellDicts.en
    autojump
    avahi
    cifs-utils
    curl
    docker
    dosfstools
    espeak
    evince
    firefox
    gimp
    gitAndTools.gitFull
    # broken again
    #gnomeExtensions.system-monitor
    gnumake
    google-chrome
    google-cloud-sdk
    hdparm
    htop
    imagemagick
    iotop
    lm_sensors
    meld
    mtools
    ntfs3g
    nextcloud-client
    openhantek6022
    pamixer
    pass
    pavucontrol
    python
    renameutils
    seafile-client
    slack
    source-code-pro
    speechd
    sshfsFuse
    teamviewer
    vlc
    wget
    zsh
    samba
    (vscode-with-extensions.override {
        vscode = vscodium;
        # When the extension is already available in the default extensions set.
        vscodeExtensions = with vscode-extensions; [
          bbenoist.Nix
          ms-kubernetes-tools.vscode-kubernetes-tools
          ms-vscode-remote.remote-ssh
          ms-azuretools.vscode-docker
          justusadam.language-haskell
          formulahendry.auto-close-tag
          redhat.vscode-yaml
          vscodevim.vim
          alanz.vscode-hie-server

        ]
        # Concise version from the vscode market place when not available in the default set.
        ++ vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "vscode-power-mode";
            publisher = "hoovercj";
            version = "2.2.0";
            sha256 = "0v1vqkcsnwwbb7xbpq7dqwg1qww5vqq7rc38qfk3p6b4xhaf8scm";
          }
          {
            name = "ecdc";
            publisher = "mitchdenny";
            version = "1.3.0";
            sha256 = "0hkiwxizdr9nfpgms65hw3v55qvqz3k2lnaji2lwx8bbb9iwal14";
          }
          {
            name = "nixfmt-vscode";
            publisher = "brettm12345";
            version = "0.0.1";
            sha256 = "07w35c69vk1l6vipnq3qfack36qcszqxn8j3v332bl0w6m02aa7k";
          }
          {
            name = "gitlens";
            publisher = "eamodio";
            version = "10.2.1";
            sha256 = "1bh6ws20yi757b4im5aa6zcjmsgdqxvr1rg86kfa638cd5ad1f97";
          }
          {
            name = "git-graph";
            publisher = "mhutchie";
            version = "1.25.0";
            sha256 = "126s0kzq0a0rp1dagyi2ks1vr91a4p8vn4y9yk2agx46xkcf8ycq";
          }
          {
            name = "code-spell-checker";
            publisher = "streetsidesoftware";
            version = "1.9.0";
            sha256 = "0ic0zbv4pja5k4hlixmi6mikk8nzwr8l5w2jigdwx9hc4zhkf713";
          }
          {
            name = "syncify";
            publisher = "arnohovhannisyan";
            version = "4.0.4";
            sha256 = "0fii948h47k6cd0cs92zmn1kirh3p9cl2h6rbc9kdp18ng4qqd64";
          }
          {
            name = "bracket-pair-colorizer-2";
            publisher = "CoenraadS";
            version = "0.2.0";
            sha256 = "0nppgfbmw0d089rka9cqs3sbd5260dhhiipmjfga3nar9vp87slh";
          }

          # databases
          {
            name = "sqltools";
            publisher = "mtxr";
            version = "0.22.11";
            sha256 = "0vrc66bzpddc2ik05r2yxpzz6l0mzf79qfq96fccnm1fmn4cc5r6";
          }
          {
            name = "sqltools-driver-mysql";
            publisher = "mtxr";
            version = "0.1.1";
            sha256 = "1mzwk0r430z46qdmyz280n61cjk22zvlcdq92w3zhs497kf9pa48";
          }
          {
            name = "sqltools-driver-sqlite";
            publisher = "mtxr";
            version = "0.1.0";
            sha256 = "01r271kpjw8g9si9ikfgcff68l7zs9xq15yx80w5bgni2d3h2hwm";
          }
          {
            name = "sqltools-driver-pg";
            publisher = "mtxr";
            version = "0.1.0";
            sha256 = "00a98fvgnhr93ihb21m7v36bzhbpnxj0snzn6sa64m1brhng0qgw";
          }
          {
            name = "mongodb-vscode";
            publisher = "mongodb";
            version = "0.1.0";
            sha256 = "1xayri5ld76i6ww1jfxfhlv0mk09kxa3wxps5j6hxdxyvyy7jccz";
          }

          # dotnet
          {
            name = "csharp";
            publisher = "ms-dotnettools";
            version = "1.22.1";
            sha256 = "1cvyn4vj20ipdmp6jhiv1a84jaxgbfpn4r1043ayassdlimvdsl8";
            # npm i
            # npm run compile
          }
          {
            name = "Ionide-fsharp";
            publisher = "Ionide";
            version = "4.14.0";
            sha256 = "0xdlknjmgn770pzpbw00gdqln9kkyksqnm1g9fcnrmclyhs639z4";
          }
          {
            name = "Ionide-Paket";
            publisher = "Ionide";
            version = "2.0.0";
            sha256 = "1455zx5p0d30b1agdi1zw22hj0d3zqqglw98ga8lj1l1d757gv6v";
          }
          {
            name = "Ionide-FAKE";
            publisher = "Ionide";
            version = "1.2.3";
            sha256 = "0ijgnxcdmb1ij3szcjlyxs2lb1kly5l26lg9z2fa7hfn67rrds29";
          }

          # haskell
          {
            name = "haskell";
            publisher = "haskell";
            version = "1.0.0";
            sha256 = "0i5dljl5m42kiwqlaplbqi4bhq59456bxs0m0w1dzk80jxyfsv0i";
          }


        ];
      })

    (nmap.override {
        graphicalSupport = true;
    })
    (vim_configurable.customize {
      name = "vim";
      vimrcConfig.customRC = ''
      syntax enable
      set smartindent
      set smartcase
      set cursorline
      set visualbell
      set hlsearch
      set incsearch
      set ruler
      set backspace=indent,eol,start
      '';
      vimrcConfig.vam.knownPlugins = pkgs.vimPlugins;
      vimrcConfig.vam.pluginDictionaries = [
        { names = [
          "vim-nix"
        ];}
      ];
    })
    # use version with seccomp fix
    (proot.overrideAttrs (oldAttrs: {
      src = fetchFromGitHub {
        repo = "proot";
        owner = "jorge-lip";
        rev = "25e8461cbe56a3f035df145d9d762b65aa3eedb7";
        sha256 = "1y4rlx0pzdg4xsjzrw0n5m6nwfmiiz87wq9vrm6cy8r89zambs7i";
      };
      version = "5.1.0.20171102";
    }))
  ];

  services.gvfs.enable = true;
  services.fwupd.enable = true;
  services.gnome3 = {
    chrome-gnome-shell.enable = true;
    gnome-keyring.enable = true;
    gnome-online-accounts.enable = true;
    gnome-online-miners.enable = true;
    gnome-user-share.enable = true;
    tracker-miners.enable = true;
    tracker.enable = true;
    sushi.enable = true;
  };
  services.earlyoom.enable = true;

  programs.seahorse.enable = true;
  programs.gnome-terminal.enable = true;
  programs.gnome-documents.enable = true;
  programs.gnome-disks.enable = true;

  #services.teamviewer.enable = true;

  # ram verdoppler
  zramSwap.enable = false;

  programs.adb.enable = true;
  programs.bash.enableCompletion = true;
  programs.zsh.enable = true;

  #environment.etc."qemu/bridge.conf".text = ''
  #  allow bridge0
  #'';
  boot.kernelParams = [ "bluetooth.disable_ertm=1" ];

  # raise limit to avoid steamplay problems
  systemd.extraConfig = "DefaultLimitNOFILE=1048576";

  programs.autojump.enable = true;

  hardware.bluetooth = {
    enable = true;
    package = pkgs.bluezFull;
  };
}

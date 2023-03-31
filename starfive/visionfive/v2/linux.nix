{ lib
, callPackage
, fetchpatch
, kernelPatches
, linuxPackagesFor 
, ... }:

let
  modDirVersion = "5.15.0";

  linuxPkg = { fetchFromGitHub, buildLinux, ... } @ args:
      buildLinux (args // {
#      inherit modDirVersion;
#      kernelPatches = [];
       #inherit modDirVersion kernelPatches;
       inherit modDirVersion;
       kernelPatches = kernelPatches ++ [ 
         { patch = ./0001-crypto-dh-constify-struct-dh-s-pointer-members.patch; }
         { patch = ./0001-drm-img-rogue-Fix-the-Makefile.patch; }
         { patch = ./visionfive-2-duplicate-init-module.patch; }
         { patch = ./visionfive-2-gpu.patch; } 
         { patch = ./visionfive-2-pl330-name-collision.patch; }

         { patch = fetchpatch {
           url = "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/patch/?id=0baced0e0938f2895ceba54038eaf15ed91032e7";
           hash = "sha256-2gAEUvc/hAOY0vjg6W6Z/BbyTW2aBGord0J6B/asllQ=";
           };
         }
       ];

      version = "${modDirVersion}-starfive-visionfive-v2";

      src = fetchFromGitHub {
        owner = "starfive-tech";
        repo = "linux";
        rev = "a87c6861c6d96621026ee53b94f081a1a00a4cc7";
        sha256 = "sha256-3qBsuKmZu8MiZp25QLgrzTR9DpC/oQXEbZ0CfSb9Z2o=";
      };

      defconfig = "starfive_visionfive2_defconfig";

      structuredExtraConfig = with lib.kernel; {
        KEXEC = yes;
        SERIAL_8250 = yes;
        SERIAL_8250_DW = yes;
        PINCTRL_STARFIVE = yes;
        DW_AXI_DMAC_STARFIVE = yes;
        PTP_1588_CLOCK = yes;
        STMMAC_ETH = yes;
        STMMAC_PCI = yes;

       # Fix build error
       # RIPE-MD and other algos appears to have been removed, correlating with https://github.com/starfive-tech/linux/commit/d210ee3fdfe8584f84f8fdd0ac4a9895d023325b
       # defconfig out of date?
       CRYPTO_RMD128 = no;
       CRYPTO_RMD160 = yes;
       CRYPTO_RMD256 = no;
       CRYPTO_RMD320 = no;
       CRYPTO_TGR192 = no;
       CRYPTO_SALSA20 = no;

       # Compile error
       USB_WIFI_ECR6600U = no;
       DRM_VERISILICON = no;

       # Own Starfive implementations
       VIDEO_IMX219 = no;
       VIDEO_OV5640 = no;
     };

     extraMeta.branch = "JH7110_VisionFive2_devel";
    } // (args.argsOverride or { }));
in lib.recurseIntoAttrs (linuxPackagesFor (callPackage linuxPkg { }))

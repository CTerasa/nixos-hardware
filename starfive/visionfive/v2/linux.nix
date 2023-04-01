{ lib, callPackage, fetchpatch, kernelPatches, linuxPackagesFor, ... }:

let
  modDirVersion = "5.15.0";

  linuxPkg = { fetchFromGitHub, buildLinux, ... }@args:
    buildLinux (args // {
      inherit modDirVersion;

      version = "${modDirVersion}-starfive-visionfive-v2";

      src = fetchFromGitHub {
        owner = "starfive-tech";
        repo = "linux";
        rev = "a87c6861c6d96621026ee53b94f081a1a00a4cc7";
        sha256 = "sha256-3qBsuKmZu8MiZp25QLgrzTR9DpC/oQXEbZ0CfSb9Z2o=";
      };

      defconfig = "starfive_visionfive2_defconfig";

      kernelPatches = kernelPatches ++ [
        { patch = ./0001-crypto-dh-constify-struct-dh-s-pointer-members.patch; }
        { patch = ./0001-drm-img-rogue-Fix-the-building-for-Nix.patch; }
        { patch = ./visionfive-2-gpu.patch; }
        { patch = ./visionfive-2-pl330-name-collision.patch; }

        # Fix the issue below by applying lodified local patch
        #         { patch = fetchpatch {
        #           url = "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/patch/?id=0baced0e0938f2895ceba54038eaf15ed91032e7";
        #           hash = "sha256-2gAEUvc/hAOY0vjg6W6Z/BbyTW2aBGord0J6B/asllQ=";
        #           };
        #         }
        { patch = ./0001-kbuild-Unify-options-for-BTF-generation-for-vmlinux-.patch; }
        {
          patch = fetchpatch {
            url =
              "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/patch/?id=b775fbf532dc01ae53a6fc56168fd30cb4b0c658";
            hash = "sha256-/zuz+R6b/I9l0wbzdgfRtonQc8jMwqpaJN4G31w63us=";
          };
        }
        # Does not apply: Non code changing commit: only chmod file;
        # Use modified local patch instead, see above
        #         { patch = fetchpatch {
        #           url = "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/patch/?id=096e34b05a439f0e607529d9404be3c3f59d2064";
        #           hash = "sha256-2gAEUvc/hAOY0vjg6W6Z/BbyTW2aBGord0J6B/asllQ=";
        #           };
        #         }
        {
          patch = fetchpatch {
            url =
              "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/patch/?id=a111f8e113c76efe7c9b3feffb4d487240d61286";
            hash = "sha256-416Ch6GXxPHJd4/UjhOBFRENOJdLe4/OwLlan0SzKD8=";
          };
        }
        {
          patch = fetchpatch {
            url =
              "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/patch/?id=f58e43184226e5e9662088ccf1389e424a3a4cbd";
            hash = "sha256-qzDnjFDGUetPfEGfxo3E695uSY5MGbWfkd9h6hUtAA4=";
          };
        }
        {
          patch = fetchpatch {
            url =
              "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/patch/?id=e39bce64e58e62dd7125b2bbed74df4f5f6017e7";
            hash = "sha256-DXZJm42f0GwVSHa1LyKQP2ezX1TOnBCZmwV6CokqmcY=";
          };
        }
      ];

      structuredExtraConfig = with lib.kernel; {
        KEXEC = yes;
        SERIAL_8250 = yes;
        SERIAL_8250_DW = yes;
        PINCTRL_STARFIVE = yes;
        DW_AXI_DMAC_STARFIVE = yes;
        PTP_1588_CLOCK = yes;
        STMMAC_ETH = yes;
        STMMAC_PCI = yes;
        VIRTIO = module;
        VIRTIO_MENU = yes;
        VIRTIO_PCI = module;
        VIRTIO_PCI_LEGACY = yes;
        VIRTIO_PCI_LIB = module;

        # Uses irq_to_desc -> not buildable as module
        RTC_DRV_STARFIVE = yes;

        # Uses sm4_expandkey and others -> some bug in the kernel fixed upstream
        CRYPTO_SM3 = yes;
        CRYPTO_LIB_SM3 = yes;
        CRYPTO_SM4 = no;
        CRYPTO_LIB_SM4 = no;
        CRYPTO_DEV_CCREE = no;

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

        # Use Starfive implementations instead of mainline
        VIDEO_IMX219 = no;
        VIDEO_OV5640 = no;

        # missing MODULE_LICENSE()
        SND_SOC_WM8960 = no;
      };

      extraMeta.branch = "JH7110_VisionFive2_devel";
    } // (args.argsOverride or { }));
in
lib.recurseIntoAttrs (linuxPackagesFor (callPackage linuxPkg { }))

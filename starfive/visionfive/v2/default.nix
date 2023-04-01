{ config, lib, pkgs, ... }:

{
  hardware.deviceTree.name = lib.mkDefault "starfive/jh7110-visionfive-v2.dtb";
  systemd.services."serial-getty@hvc0".enable = lib.mkDefault false;
  environment.systemPackages = with pkgs; lib.mkDefault [ mtdutils ];

  boot = {
    # Force no ZFS (from nixos/modules/profiles/base.nix) until updated to kernel 5.15
    supportedFilesystems = lib.mkForce [ "btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" ];
    consoleLogLevel = lib.mkDefault 7;
    kernelPackages = lib.mkDefault (pkgs.callPackage ./linux.nix { inherit (config.boot) kernelPatches; });

    kernelParams = lib.mkDefault [
      "console=tty0"
      "console=ttyS0,115200n8"
      "earlycon=sbi"
    ];

    initrd.kernelModules = lib.mkDefault [
      "dw-axi-dmac-platform"
      "dw_mmc-pltfm"
      "spi-dw-mmio"
    ];

    loader = {
      grub.enable = lib.mkDefault false;
      generic-extlinux-compatible.enable = lib.mkDefault true;
    };
  };
}

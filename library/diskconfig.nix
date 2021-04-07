# Convert a given configuration expression into an expression which
# correctly configures a nixos system for things like swap, filesystems,
# crypt on startup, etc.

config:
{ ... }:
with builtins;
let
  hostname = config.hostname;
  lvs = attrNames config.lvm;
  swaps = filter (lv: config.lvm.${lv}.fs == "swap") lvs;
  fses = filter (lv: config.lvm.${lv}.fs != "swap") lvs;
  bootfs = {
    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = if config.disk.efi-boot then "vfat" else "ext4";
    };
  };
  update = a: b: a // b;

  swapDevices = map (
    lv:
      {
        label = lv;
      }
  ) swaps;

  fileSystems = bootfs // (
    foldl' update {} (
      map (
        lv:
          {
            "${config.lvm.${lv}.mount}" = {
              device = "/dev/disk/by-label/${lv}";
              fsType = "${config.lvm.${lv}.fs}";
            };
          }
      ) fses
    )
  );

  yubi-crypt = let
    saltlen = if config.yubikey ? salt-length then config.yubikey.salt-length else 16;
    keylen = (if config.fde ? key-size then config.fde.key-size else 512) / 8;
    storage = "/dev/${config.disk.prefix}1";
    fs = if config.disk.efi-boot then "vfat" else "ext4";
  in
    if config.yubikey.enable then {
      yubikey = {
        slot = 2;
        twoFactor = true;
        keyLength = keylen;
        saltLength = saltlen;
        storage = {
          device = storage;
          fsType = fs;
          path = "/crypt-storage/default";
        };
      };
    } else {};

  crypt-config = {
    boot.initrd.luks = {
      devices = {
        "pv-${hostname}" = {
          device = "/dev/${config.disk.prefix}2";
          preLVM = true;
          allowDiscards = true;
        } // yubi-crypt;
      };
      yubikeySupport = config.yubikey.enable;
    };
  };

  all-blocks = [
    { swapDevices = swapDevices; }
    { fileSystems = fileSystems; }
  ] ++ (if config.fde.enable then [ crypt-config ] else []);

in
foldl' update {} all-blocks

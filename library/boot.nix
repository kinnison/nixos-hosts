# Convert a configuration into a set of bootloader settings

config:
{ ... }:
let
  bios-boot = {
    boot.loader.grub.enable = true;
    boot.loader.grub.version = 2;
    boot.loader.grub.device = "/dev/${config.disk.base}";
  };
  efi-boot = {
    boot.loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = (if (if config ? efi-in-subdir then
          config.efi-in-subdir
        else
          false) then
          "/boot/efi"
        else
          "/boot");
      };
      grub = {
        devices = [ "nodev" ];
        enable = true;
        efiSupport = true;
      } // (if config ? grubExtras then {
        extraEntries = config.grubExtras;
      } else
        { });
    };
  };
in if config.disk.efi-boot then efi-boot else bios-boot

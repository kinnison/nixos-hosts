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
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
        editor = false;
      };
    };
  };
in
if config.disk.efi-boot then efi-boot else bios-boot

# Configuration expression.
# For 5900x desktop
#
{
  disk = {
    base = "nvme1n1";
    prefix = "nvme1n1p";
    bootsize = "512MiB";
    efi-boot = true;
  };

  fde.enable = false;
  yubikey.enable = true;

  use-hwconf-mounts = true;
  lvm = {};

  grubExtras = ''
      menuentry "Windows" {
        insmod part_gpt
        insmod fat
        insmod search_fs_uuid
        insmod chain
        search --fs-uuid --set=root 020B-156F
        chainloader /EFI/Microsoft/Boot/bootmgfw.efi
      }
  '';

  efi-in-subdir = true;

  user = {
    name = "dsilvers";
    passwd = "$5$rounds=1000000$yU6CboKQelTXD$57k5Y7mu78A.XwH9OJ4SemKGEYP42ES4zz.5/D0qAOD";
    groups = [];
  };
}

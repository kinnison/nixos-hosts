# Configuration expression.
# For X201 laptop - parasomnix
#
{
  disk = {
    base = "sda";
    prefix = "sda";
    bootsize = "512MiB";
    efi-boot = false;
  };

  fde.enable = true;
  yubikey.enable = true;

  lvm = {
    root = {
      size = "10G";
      fs = "ext4";
      mount = "/";
    };
    nix = {
      size = "30G";
      fs = "ext4";
      mount = "/nix";
    };
    home = {
      size = "30G";
      fs = "ext4";
      mount = "/home";
    };
    swap = {
      size = "8G";
      fs = "swap";
    };
  };

  user = {
    name = "dsilvers";
    passwd = "$5$rounds=1000000$yU6CboKQelTXD$57k5Y7mu78A.XwH9OJ4SemKGEYP42ES4zz.5/D0qAOD";
    groups = [];
  };
}

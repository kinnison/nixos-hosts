# Configuration expression.
# For Daniel's laptop
#
# We already know that our hostname is `hypnicjerk` otherwise we'd not have got here
# as such, what we care about is the main system configuration
{
  disk = {
    base = "nvme0n1";
    prefix = "nvme0n1p";
    bootsize = "4GiB";
    efi-boot = true;
  };

  fde.enable = true;
  yubikey.enable = true;

  lvm = {
    root = {
      size = "20G";
      fs = "ext4";
      mount = "/";
    };
    nix = {
      size = "50G";
      fs = "ext4";
      mount = "/nix";
    };
    home = {
      size = "20G";
      fs = "ext4";
      mount = "/home";
    };
    swap = {
      size = "32G";
      fs = "swap";
    };
  };

  user = {
    name = "dsilvers";
    passwd = "$5$rounds=1000000$yU6CboKQelTXD$57k5Y7mu78A.XwH9OJ4SemKGEYP42ES4zz.5/D0qAOD";
    groups = [];
  };
}

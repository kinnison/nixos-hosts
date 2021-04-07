# Configuration expression.
# For test VM
#
# We already know that our hostname is `test` otherwise we'd not have got here
# as such, what we care about is the main system configuration
{
  disk = {
    base = "vda";
    prefix = "vda";
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
      size = "20G";
      fs = "ext4";
      mount = "/nix";
    };
    home = {
      size = "10G";
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

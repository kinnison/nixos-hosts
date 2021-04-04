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
}

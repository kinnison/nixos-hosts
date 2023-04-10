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
    passwd = "$6$jhPpRWgH6hEjTTmH$BZYw8lLV2lalgnsLdbm5r3JsZWxXwf/C7ldSqNaiz8i2xY/gHDEMmn4LK85MzSsOQOpbbZ334s90sPdCDDymH1";
    groups = [];
  };
}

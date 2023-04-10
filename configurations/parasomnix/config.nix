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
    passwd = "$6$jhPpRWgH6hEjTTmH$BZYw8lLV2lalgnsLdbm5r3JsZWxXwf/C7ldSqNaiz8i2xY/gHDEMmn4LK85MzSsOQOpbbZ334s90sPdCDDymH1";
    groups = [];
  };
}

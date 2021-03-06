# Core configuration, predicated by the system configuration

sysconfig:
{ lib, pkgs, config, ... }:
let
  configUsers = import ../library/users.nix sysconfig;
  bootLoader = import ../library/boot.nix sysconfig;
  diskConfig = import ../library/diskconfig.nix sysconfig;
in
{
  imports = [
    diskConfig
    bootLoader
    configUsers
    ./defaults.nix
  ] ++ (
    if sysconfig.yubikey.enable then [ ./pam-yubikey.nix ] else []
  );

  networking.hostName = sysconfig.hostname;

  # We are not sufficiently unhappy about unfree to deny ourselves the right
  nixpkgs.config.allowUnfree = true;

  # And all our systems need fstrim
  services.fstrim.enable = true;
}

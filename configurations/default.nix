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
  ];

  networking.hostName = sysconfig.hostname;
}

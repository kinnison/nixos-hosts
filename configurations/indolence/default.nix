# Test VM configuration

{ pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../gui.nix
    ../steam.nix
  ];

  sops.defaultSopsFile = ./secrets/secrets.yaml;

  sops.secrets.ssh_host_rsa_key = {};

  services.xserver.videoDrivers = [ "nvidia" ];

}

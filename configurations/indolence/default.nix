# Test VM configuration

{ pkgs, lib, inputs, ... }:

{
  imports =
    [ ./hardware-configuration.nix ../gui.nix ../steam.nix ../docker.nix ];

  sops.defaultSopsFile = ./secrets/secrets.yaml;

  sops.secrets.ssh_host_rsa_key = { };

  services.xserver.videoDrivers = [ "nvidia" ];

  services.printing = { enable = true; };
  services.printing.drivers = [ pkgs.hplip ];
  services.teamviewer.enable = true;
}

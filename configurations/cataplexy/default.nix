# Daniel's laptop configuration

{ pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../gui.nix
    ../docker.nix
  ];

  sops.defaultSopsFile = ./secrets/secrets.yaml;

  sops.secrets.ssh_host_rsa_key = { };

  hardware.trackpoint = {
    enable = true;
    emulateWheel = true;
  };

  services.xserver.videoDrivers = [ "intel" ];
  services.xserver.dpi = 150;
}

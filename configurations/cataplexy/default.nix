# Daniel's laptop configuration

{ pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../gui.nix
    ../docker.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_5_16;
  boot.kernelParams = [ "i915.enable_psr=0" ];

  sops.defaultSopsFile = ./secrets/secrets.yaml;

  sops.secrets.ssh_host_rsa_key = { };

  hardware.trackpoint = {
    enable = true;
    emulateWheel = true;
  };

  services.xserver.videoDrivers = [ "intel" ];
  services.xserver.dpi = 150;
  services.xserver.deviceSection = ''
  Option "DRI" "3"
'';
}

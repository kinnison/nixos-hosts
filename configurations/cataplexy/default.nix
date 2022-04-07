# Daniel's laptop configuration

{ pkgs, lib, inputs, ... }:

{
  imports =
    [ ./hardware-configuration.nix ../gui.nix ../docker.nix ../steam.nix ];

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

  services.tlp = {
    enable = true;
    settings = {
      START_CHARGE_THRESH_BAT0 = 70;
      STOP_CHARGE_THRESH_BAT0 = 85;
      START_CHARGE_THRESH_BAT1 = 70;
      STOP_CHARGE_THRESH_BAT1 = 85;
    };
  };
}

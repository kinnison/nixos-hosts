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
  services.udev.packages = [ pkgs.qmk-udev-rules ];
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      ovmf.enable = true;
    };
  };
  environment.systemPackages = with pkgs; [ virt-manager ntfs3g ];

  services.hardware.openrgb = {
    enable = true;
    motherboard = "amd";
  };
}

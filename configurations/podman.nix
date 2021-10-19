# Default configuration for Podman

{ config, pkgs, lib, ... }:

{
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      dockerSocket.enable =
        true; # Required to use docker-compose with Podman as a backend
    };
  };

  environment.systemPackages = with pkgs; [ crun ];
}

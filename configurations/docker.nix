# Default configuration for Podman

{ config, pkgs, lib, ... }:

{
  virtualisation = {
    docker = {
      enable = true;
      enableOnBoot = true;
    };
  };

  environment.systemPackages = with pkgs; [ crun docker-compose ];
}

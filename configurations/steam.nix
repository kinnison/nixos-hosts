# Default configuration for everything
# Things go here which go on *ALL* hosts

{ lib, pkgs, config, ... }:

{
  programs.steam.enable = true;
  environment.systemPackages = with pkgs; [ protontricks ];
}

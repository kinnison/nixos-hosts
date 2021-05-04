# Default configuration for everything
# Things go here which go on *ALL* hosts

{ lib, pkgs, config, ... }:

{
  # Core X server and related configuration needed for any computer
  # I use with a GUI
  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.mate.enable = true;
  environment.mate.excludePackages = [
    pkgs.mate.pluma
  ];
  services.xserver.displayManager.defaultSession = "mate";
  services.xserver.windowManager.xmonad = {
    enable = true;
    enableContribAndExtras = true;
  };
  programs.nm-applet.enable = true;
}

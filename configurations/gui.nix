# Default configuration for everything
# Things go here which go on *ALL* hosts

{ lib, pkgs, config, ... }:

{
  # Core X server and related configuration needed for any computer
  # I use with a GUI
  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.mate.enable = true;
  environment.mate.excludePackages = with pkgs.mate; [
    eom
    mate-applets
    mate-backgrounds
    mate-calc
    mate-indicator-applet
    mate-media
    mate-netbook
    mate-sensors-applet
    mate-system-monitor
    mate-user-guide
    mate-utils
    mozo
    pluma
  ];
  services.xserver.displayManager.defaultSession = "mate";
  services.xserver.windowManager.xmonad = {
    enable = true;
    enableContribAndExtras = true;
  };
  programs.nm-applet.enable = true;

  qt5 = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

}

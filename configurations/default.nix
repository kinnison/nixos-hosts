# Default package configurations for all hosts no matter what

sysconfig:

{ lib, pkgs, ... }:
let
  configUsers = import ../library/users.nix sysconfig;
in
{
  # Stash the system configuration expression so we can potentially use it
  # in many places later...
  _sysconfig = sysconfig;

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  boot = {
    cleanTmpDir = true;
    plymouth.enable = true;
  };

  time.timeZone = lib.mkDefault 100 "Europe/London";

  users = {
    defaultUserShell = pkgs.zsh;
  };

  inherit (configUsers) users;

  programs = {
    zsh.enable = true;
  };

  fonts = {
    enableDefaultFonts = true;
    fonts = with pkgs; [
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      fira-code
      fira-code-symbols
      inconsolata
    ];

    fontconfig = {
      defaultFonts = {
        serif = [ "NotoSerif" ];
        sansSerif = [ "NotoSans" ];
        monospace = [ "FiraCode" ];
      };
    };
  };

  networking.hostName = sysconfig.hostname;

  sound.enable = true;
  hardware.pulseaudio.enable = true;

  services.udev.packages = with pkgs; [ yubikey-personalization ];

  # Do not alter this unless instructed to during an upgrade to a newer
  # base nixos version
  system.stateVersion = "20.09";
}

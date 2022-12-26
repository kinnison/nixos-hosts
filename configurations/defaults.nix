# Default configuration for everything
# Things go here which go on *ALL* hosts

{ lib, pkgs, config, ... }:

{
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings = { auto-optimise-store = true; };
  };

  boot = {
    cleanTmpDir = true;
    # plymouth.enable = true;
  };

  time.timeZone = lib.mkDefault "Europe/London";
  i18n.defaultLocale = lib.mkDefault "en_GB.UTF-8";
  console.keyMap = lib.mkDefault "uk";

  users = { defaultUserShell = pkgs.zsh; };

  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
    autosuggestions.enable = true;
    vteIntegration = true;
  };

  fonts = {
    enableDefaultFonts = true;
    fonts = with pkgs; [
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      fira
      fira-mono
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

  sound.enable = true;
  hardware.pulseaudio.enable = true;

  services.udev.packages = with pkgs; [ yubikey-personalization ];
  services.openssh.enable = true;

  networking.networkmanager.enable = true;

  # Firmware management
  services.fwupd.enable = true;

  environment.systemPackages = with pkgs; [
    git # always need git
    home-manager # for homedirs
    vim # because why wouldn't you?
    gnumake # because makefiles are useful everywhere, right?
  ];

  # Do not alter this unless instructed to during an upgrade to a newer
  # base nixos version
  system.stateVersion = "21.05";
}

# This module defines a small NixOS installation CD.  It does not
# contain any graphical stuff.
{ config, pkgs, nixpkgs, ... }:
{
  imports = [
    # Promoted to top level
    #<nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>

    # Provide an initial copy of the NixOS channel so that the user
    # doesn't need to run "nix-channel --update" first.
    # Promoted to top level
    #<nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];

  isoImage.squashfsCompression = "zstd -Xcompression-level 10";

  environment.systemPackages = with pkgs; [
    yubikey-personalization
    yubico-pam
    nodejs-12_x
    gnumake
    pinentry
    git
    openssl
    installer.pbkdf2-sha512
  ];

  programs.gnupg.agent.enable = true;
  programs.gnupg.agent.pinentryFlavor = "curses";

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  services.udev.packages = [ pkgs.yubikey-personalization ];

  services.sshd.enable = true;
  services.thinkfan.enable = true; # For thinkpad laptops this is useful to prevent overheating on old units.

  i18n.defaultLocale = "en_GB.UTF-8";
  console.keyMap = "uk";
  time.timeZone = "Europe/London";

  users.users.nixos.openssh.authorizedKeys.keys = [ "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLoJTD9hp6oyx0skgWKpqfasjGoaMf2M6qQZhT+NqxXOKpcBz7jBu5DVlBbEE29Ar1ZYMMHa7AzsTgyLtMRougg= dsilvers@listless" ];

  # For wifi etc.
  networking.network-manager.enable = true;

}

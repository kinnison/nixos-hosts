{ pkgs, ... }:
{
  security.pam.yubico = {
    enable = true;
    control = "required";
    mode = "challenge-response";
  };

  environment.systemPackages = with pkgs; [
    yubikey-personalization
    yubico-pam
  ];
}

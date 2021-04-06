{ ... }:
{
  security.pam.yubico = {
    enable = true;
    control = "required";
    mode = "challenge-response";
  };
}

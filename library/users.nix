# Turn a given config into the relevant users stanza
config:
{ ... }:
{
  users.users.${config.user.name} = {
    isNormalUser = true;
    extraGroups = config.user.groups ++ [ "networkmanager" "wheel" ];
  } // (if config.user ? passwd then { hashedPassword = config.user.passwd; } else {});
  users.mutableUsers = false;
}

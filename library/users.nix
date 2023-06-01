# Turn a given config into the relevant users stanza
config:
{ ... }: {
  users.users.${config.user.name} = {
    isNormalUser = true;
    extraGroups = config.user.groups ++ [ "networkmanager" "wheel" "docker" "libvirtd" ];
  } // (if config.user ? passwd then {
    hashedPassword = config.user.passwd;
  } else
    { });
  users.mutableUsers = false;
  services.xserver.displayManager.sessionCommands = ''
    . /etc/profiles/per-user/${config.user.name}/etc/profile.d/hm-session-vars.sh
  '';
}

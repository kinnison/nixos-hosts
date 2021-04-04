# Convert a given configuration expression into an expression which
# correctly configures a nixos system for things like swap, filesystems,
# crypt on startup, etc.

config:
{ ... }:
with builtins;
let
  hostname = config.hostname;
  lvs = attrNames config.lvm;
  swaps = filter (lv: config.lvm.${lv}.fs == "swap") lvs;
  fses = filter (lv: config.lvm.${lv}.fs != "swap") lvs;
  update = a: b: a // b;

  swapDevices = map (
    lv:
      {
        label = lv;
      }
  ) swaps;

  fileSystems = foldl' update {} (
    map (
      lv:
        {
          "${config.lvm.${lv}.mount}" = {
            device = "/dev/disk/by-label/${lv}";
            fsType = "${config.lvm.${lv}.fs}";
          };
        }
    ) fses
  );

  crypt-config = {
    boot.initrd.luks.devices = {
      "pv-${hostname}" = {
        device = "/dev/${config.disk.prefix}2";
        preLVM = true;
        allowDiscards = true;
      };
    };
  };

  all-blocks = [
    { swapDevices = swapDevices; }
    { fileSystems = fileSystems; }
  ] ++ (if config.fde.enable then [ crypt-config ] else []);

in
foldl' update {} all-blocks

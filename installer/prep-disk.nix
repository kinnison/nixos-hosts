# Prepare the raw disk
# This will produce a script which uses parted to prepare the disk for
# formatting.

{ hostname, config }:
let
  base = config.disk.base;
  is-efi = config.disk.efi-boot;
  bootsize = config.disk.bootsize;
  prefix = config.disk.prefix;
  parted-script = ''
    _parted_script () {
        echo "mklabel ${if is-efi then "gpt" else "msdos"}"
        echo "mkpart 1 1 ${bootsize}"
        echo "set 1 ${if is-efi then "esp" else "legacy_boot"} on"
        echo "mkpart 2 ${bootsize} 100%"
        echo "set 2 lvm on"
    }

    echo "*** Partitioning /dev/${base} for use"
    _parted_script | parted --script --align optimal /dev/${base}

  '';

  lvm-pvname = "pv-${hostname}";
  lvm-pvdevice = if config.fde.enable then "/dev/mapper/${lvm-pvname}" else "/dev/${prefix}2";
  lvm-vgname = "${hostname}";
  crypt-cipher = if config.fde ? cipher then config.fde.cipher else "aes-xts-plain64";
  crypt-key-size = if config.fde ? key-size then config.fde.key-size else "512";
  crypt-hash = if config.fde ? hash then config.fde.hash else "sha512";
  crypt-setup = if config.fde.enable then ''
    echo "*** Setting up FDE using /dev/${prefix}2"
    cryptsetup --cipher ${crypt-cipher} --key-size ${crypt-key-size} --hash ${crypt-hash} luksFormat /dev/${prefix}2
    cryptsetup luksOpen /dev/${prefix}2 ${lvm-pvname}
  '' else ''
    echo "*** No crypt setup required"
  '';

  lvm-volumes = builtins.attrNames config.lvm;


  lvm-setup = ''
    echo "*** Setting up LVM using ${lvm-pvdevice} as the physical volume"
    pvcreate ${lvm-pvdevice}
    vgcreate ${lvm-vgname} ${lvm-pvdevice}
    ${builtins.concatStringsSep "\n" (
    map (
      volname: let
        volsize = config.lvm.${volname}.size;
      in
        "lvcreate --size ${volsize} --name ${volname} ${lvm-vgname}"
    ) lvm-volumes
  )} 
    vgchange --available y ${lvm-vgname}   
  '';

  mkfs = {
    ext4 = dev: name:
      "mkfs.ext4 -F -L ${name} ${dev}";
    swap = dev: name:
      "mkswap -f -L ${name} ${dev}";
    vfat = dev: name:
      "mkfs.fat -F 32 -n ${name} ${dev}";
  };

  make-volumes = [
    (
      if config.disk.efi-boot then
        (mkfs.vfat "/dev/${prefix}1" "boot")
      else
        (mkfs.ext4 "/dev/${prefix}1" "boot")
    )
  ] ++ map (
    volname:
      let
        volfs = config.lvm.${volname}.fs;
      in
        mkfs.${volfs} "/dev/mapper/${lvm-vgname}-${volname}" volname
  ) lvm-volumes;

  make-filesystems = ''
    echo "*** Making filesystems ready for use..."
    ${builtins.concatStringsSep "\n" make-volumes}
  '';

  all-filesystems = [ { mount = "/boot"; device = "/dev/disk/by-label/boot"; } ] ++ map (
    volname:
      let
        volmount = config.lvm.${volname}.mount;
      in
        { mount = volmount; device = "/dev/mapper/${lvm-vgname}-${volname}"; }
  ) (builtins.filter (volume: config.lvm.${volume}.fs != "swap") lvm-volumes);
  sorted-filesystems = builtins.sort
    (
      first: second: let
        len = builtins.stringLength;
      in
        (len first.mount) < (len second.mount)
    ) all-filesystems;
  all-swaps = map (volname: "swapon -d /dev/mapper/${lvm-vgname}-${volname}") (
    builtins.filter (
      volume: config.lvm.${volume}.fs == "swap"
    ) lvm-volumes
  );
  mount-actions = all-swaps ++ map (
    { mount, device }:
      ''
        while ! test -r ${device}; do
          echo "*** Waiting for ${device}"
          sleep 1
        done
        mkdir -p /mnt${mount}
        mount ${device} /mnt${mount}''
  ) sorted-filesystems;

  mount-everything = ''
    echo "*** Mounting everything up..."
    
    ${builtins.concatStringsSep "\n" mount-actions}
  '';
in
''#!/bin/sh

set -e

echo "*** Beginning disk setup for ${hostname}"

# Partition /dev/${base} ready for use

${parted-script}

# Set up encrypted disk if needed

${crypt-setup}

# Now set up the LVM

${lvm-setup}

# Now make filesystems

${make-filesystems}

# Now mount everything

${mount-everything}
''

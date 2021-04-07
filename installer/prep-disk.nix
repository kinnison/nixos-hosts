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
  salt-length = if config.yubikey ? salt-length then config.yubikey.salt-length else 16;
  crypt-setup = if config.fde.enable then ''
    echo "*** Setting up FDE using /dev/${prefix}2"
    echo -n "$RECOVERY" > /tmp/recovery.key
    cryptsetup --batch-mode --cipher ${crypt-cipher} --key-size ${crypt-key-size} --hash ${crypt-hash} luksFormat /dev/${prefix}2 /tmp/recovery.key
    echo "*** Verifying we can luksOpen with recovery passphrase"
    echo -n "$RECOVERY" | cryptsetup --allow-discards luksOpen /dev/${prefix}2 ${lvm-pvname}
    ${if config.yubikey.enable then ''
    echo "*** Adding a passphrase using the yubkey (slot 2)..."
    rbtohex() {
        ( od -An -vtx1 | tr -d ' \n' )
    }
    hextorb() {
      ( tr '[:lower:]' '[:upper:]' | sed -e 's/\([0-9A-F]\{2\}\)/\\\\\\x\1/gI'| xargs printf )
    }
    while true; do
      echo -n "Passphrase for use with yubikey FDE: "
      read -s pw1
      echo
      echo -n "Enter passphrase again: "
      read -s pw2
      echo
      if [ "x$pw" == "x$pw2" ]; then
        echo "Passwords match, continuing"
        continue
      fi
      echo "Passwords do not match, try again..."
    done
    SALT_LENGTH=${salt-length}
    salt="$(dd if=/dev/random bs=1 count=$SALT_LENGTH 2>/dev/null | rbtohex)"
    echo "   *** Computing the initial challenge/response with openssl and the yubikey"
    challenge="$(echo -n $salt | openssl dgst -binary -sha512 | rbtohex)"
    response="$(ykchalresp -2 -x $challenge 2>/dev/null)"
    KEY_LENGTH=${crypt-key-size}
    ITERATIONS=1000000
    k_luks="$(echo -n "$pw1" | pbkdf-sha512 $((KEY_KENGTH / 8)) $ITERATIONS $response | rbtohex)"
    echo -n "$k_luks" | hextorb | cryptsetup --key-file=/tmp/recovery.key luksAddKey /dev/${prefix}2
  '' else ''
    echo "*** Adding user password to crypt..."
    cryptsetup --key-file=/tmp/recovery.key luksAddKey /dev/${prefix}2
  ''}
    echo "*** Crypt setup completed"
  '' else ''
    echo "*** No crypt setup required"
  '';

  write-out-luks-stuff = if config.fde.enable && config.yubikey.enable then ''
    echo "*** Writing out the yubikey data to /mnt/boot..."
    mkdir -p /mnt/boot/crypt-storage
    echo -ne "$salt\n$ITERATIONS" > /mnt/boot/crypt-storage/default
  '' else "";

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

# Now fill in any post-hoc

${write-out-luks-stuff}

''

# Daniel's NixOS Host configuration

This repository contains configuration for hosts and also an installer capable
of installing from this repository. In addition it contains handy Make targets
which can build a system using this repo.

# Secrets

Secrets are managed in this repository using `sops` - if you're adding new
secrets, new paths to secrets, etc. you will need to manage `.sops.yaml`
appropriately.

# The installer

The installer is defined in `installer/iso.nix` and does not contain everything
directly. It's simply a minimal (text mode) installer with the relevant packages
needed to stand a chance of running the install.

You build the installer with `make iso`

# System definitions

In order for this system to work, you need a system definition in the
`configurations` directory. The `test` configuration is an example you can use
if you want something to work from. At minimum any new host will need the
following pre-configuring...

1. Ensure there's an entry in `.sops.yaml` - for now you won't have a host key
   for the host, so just skip that and just put the `daniel` key in for the host
2. Make `configurations/$hostname/{files,secrets}`
3. Populate `configurations/$hostname/config.nix` with the host's basic
   definition.
4. If you happen to already have a `hardware-configuration.nix` suitable, drop
   that in too, otherwise we'll handle that later.
5. Populate `configurations/$hostname/default.nix` with the bare minimum you'll
   want to not hate the host.
6. Now we want to define the host's SSH keys. This is a necessary first step
   which will provide the host with an identity we can use later.
   To do this, run `make gen-ssh-keys HOST=$hostname`. This will require that
   the primary GPG key is available.
7. Part of the output of this is the fingerprint of the host key for this host.
   Edit `.sops.yaml` and populate that host key into it, and mark the subtree
   for including that key.
8. We're almost done, now run `make update-keys HOST=$hostname` which will
   ensure that the secrets are appropriately encrypted.
9. If you're intending to use FDE on this host then you will need to generate
   a recovery key-file which will be programmed into slot zero of the LUKS.
   to do this, run `make gen-luks-recovery HOST=$hostname`. This will be
   encrypted with sops and so will be easy to manage. Note, the recovery key
   will still be a 'passphrase' so it _can_ be typed into a system to boot it.
10. Ensure the dotfiles repo you intend to use has a configuration for the new
    system ready to go.
11. Write a system definition into the `flake.nix` file which anchors the whole
    shebang.
12. Commit all that to the repo, then run `nix flake update --commit-lock-file`,
    push to your remote, and you're ready to rock and roll.

# Dotfiles

Be aware this module uses
[Daniel's dotfiles](https://github.com/kinnison/dotfiles/) to satisfy the
initial user's home directory needs. It uses home-manager for this.

Right now, I think this repo is the only way to successfully apply such
dotfiles, sorry.

# Performing an installation

Assuming you have followed the above and prepared the host configuration you
desire, the installation process (messy though it is) is currently:

1. Boot the ISO image built via `make iso` and ensure you have networking. This
   may involve running `sudo nmcli device wifi connect APNAME password PASSWORD`.
2. Acquire a copy of this repository (trivially `git clone https://...`)
3. Plug in your yubikey containing Daniel's GPG key and `cd nixos-hosts`.
4. If you run `make help` you'll see this sequence, but you can help things
   along by `export HOST=whatever` rather than passing `HOST=` to all the
   make targets...
5. `make prepare-gpg` -- This will set up the GPG key for use, ensure it works
6. `make disk` -- If you didn't export `HOST` above, set it on this. This will
   do the luksFormat, make LVM, filesystems, and mount them all up into /mnt
7. If you lack it, you can `make gen-hardware-config` now to write out the config.
   Remember to commit it and push later once everything is done. This can be
   done after booting into the new system as you see fit.
   If you're using a yubikey you should check for usbhid in this or it won't work
   later.
   Once you've done this, you should git add it before you proceed, or the flake
   won't work.
8. `make copy-config` -- This will copy the current git tree into /mnt/etc/nixos
9. `make provision-ssh` -- this provision's the hosts SSH keys you made above,
   this ensures that if you have to reinstall a system it will have the same
   public SSH identity (and that it can access its secrets since they're
   encrypted to the SSH identity)
10. `make install` -- this actually runs the installation.
11. Once the installation completes, you can run `make configure-user` to ensure
    that any user configuration (passwords, yubikey chalresp, etc.) is done.
12. Once all that is done, you _may_ want to enter the OS with `make enter` just
    make any fiddlings.
13. Now you can reboot into your new system.

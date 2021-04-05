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
9. The **final** thing you need to do is to write a system definition into the
   `flake.nix` file which anchors the whole shebang.
10. Commit all that to the repo and you're ready to rock and roll.

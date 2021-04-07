default: iso

clean:
	$(RM) result

iso:
	nix build -v '.#nixosConfigurations.installer.config.system.build.isoImage' && ls -lh result/iso/*

gc:
	nix-collect-garbage

help:
	@echo "Everything will sudo as needed, no need for you to do so"
	@echo "---"
	@echo "In general, run the following in-order"
	@echo "---"
	@echo "prepare-gpg - will prepare the system for GPG"
	@echo "disk - will set up the disk, needs HOST=..."
	@echo "copy-config - will copy the config to /mnt, needs disk"
	@echo "provision-ssh - will provision the SSH host keys, needs HOST=... and prepare-gpg"
	@echo "install - will do the nixos installation, needs HOST=... and all the above"
	@echo "configure-user - will then configure your user's password etc."
	@echo "---"
	@echo "enter - utility to 'enter' the install as root"

# Needs --impure because it's a sodding pain
install:
	sudo nixos-install --root /mnt --flake "/mnt/etc/nixos#$(HOST)" -v --impure

enter:
	sudo nixos-enter --root /mnt

configure-user: configurations/$(HOST)/config.nix
	@USER=$$($(MAKE) -s username); PAMYUBI=$$($(MAKE) -s pam-yubico-enabled); \
	echo "*** Set $${USER}'s password"; \
	sudo nixos-enter --root /mnt -- passwd $${USER}; \
	if [ "x$$PAMYUBI" = "xtrue" ]; then \
		echo "*** Set up yubikey entry for $${USER}"; \
		sudo nixos-enter --root /mnt -- sudo -u $${USER} -H ykpamcfg -2 -v; \
	fi


username: configurations/$(HOST)/config.nix
	@nix eval --impure --raw --expr '(import configurations/$(HOST)/config.nix).user.name'

pam-yubico-enabled: configurations/$(HOST)/config.nix
	@nix eval --impure --expr 'let config = (import configurations/$(HOST)/config.nix); in if config.user ? yubikey then config.user.yubikey else false'

copy-config:
	sudo mkdir -p /mnt/etc/nixos
	sudo cp -av . /mnt/etc/nixos

disk: configurations/$(HOST)/config.nix
	SCRIPT=$$(nix eval --impure --raw --expr 'builtins.toFile "disk.sh" (import installer/prep-disk.nix { hostname = "$(HOST)"; config = (import configurations/$(HOST)/config.nix);})'); \
	sudo bash $$SCRIPT

prepare-gpg:
	for KEY in keys/users/*.asc; do gpg --import $$KEY; done
	gpg --card-status
	gpg --list-secret-keys

provision-ssh: configurations/$(HOST)/secrets/secrets.yaml
	sudo mkdir -p /mnt/etc/ssh
	for PUB in configurations/$(HOST)/files/ssh_host_*_key.pub; do \
		sudo cp $$PUB /mnt/etc/ssh; \
		KEY=$$(basename $$PUB .pub); \
		echo $$KEY; \
		nix develop -c sops -d --extract '["'$$KEY'"]' configurations/$(HOST)/secrets/secrets.yaml | sudo tee /mnt/etc/ssh/$$KEY >/dev/null; \
	done
	sudo chown root: /mnt/etc/ssh/*
	sudo chmod 0600 /mnt/etc/ssh/*
	sudo chmod 0644 /mnt/etc/ssh/*.pub

gen-ssh-keys:
	echo "Preparing host keys for $(HOST)"
	mkdir -p configurations/$(HOST)/files
	mkdir -p configurations/$(HOST)/secrets
	if ! test -r configurations/$(HOST)/secrets/secrets.yaml ; then \
	  echo OK; \
	else \
	  exit 1; \
	fi
	touch configurations/$(HOST)/secrets/secrets.yaml
	for keytype in ed25519 rsa; do \
		if [ ! -r configurations/$(HOST)/files/ssh_host_$${keytype}_key.pub ]; then \
			ssh-keygen -t $${keytype} -N '' -f configurations/$(HOST)/files/ssh_host_$${keytype}_key; \
			(echo "ssh_host_$${keytype}_key: |"; \
			 sed -e's/^/    /' < configurations/$(HOST)/files/ssh_host_$${keytype}_key) >> configurations/$(HOST)/secrets/secrets.yaml; \
			$(RM) -f configurations/$(HOST)/files/ssh_host_$${keytype}_key; \
		fi \
	done
	nix develop -c sops -e -i configurations/$(HOST)/secrets/secrets.yaml
	mkdir -p keys/hosts
	nix develop -c sops -d --extract '["ssh_host_rsa_key"]' configurations/$(HOST)/secrets/secrets.yaml | \
	    nix-shell -p ssh-to-pgp --run "ssh-to-pgp -o keys/hosts/$(HOST).asc"

gen-luks-recovery: configurations/$(HOST)/secrets/secrets.yaml
	echo "Preparing LUKS recovery for $(HOST)"
	PW=$$(nix develop -c pwgen -c -n -s 32 1); \
	nix develop -c sops --set '["luks-recovery-passphrase"] "'$${PW}'"' configurations/$(HOST)/secrets/secrets.yaml

update-keys: configurations/$(HOST)/secrets/secrets.yaml
	nix develop -c sops updatekeys $<

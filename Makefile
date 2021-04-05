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

# Needs --impure because it's a sodding pain
install:
	sudo nixos-install --root /mnt --flake "/mnt/etc/nixos#$(HOST)" -v --impure

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
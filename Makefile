default: iso

clean:
	$(RM) result

iso:
	nix build -v '.#nixosConfigurations.installer.config.system.build.isoImage' && ls -lh result/iso/*

gc:
	nix-collect-garbage

disk: configurations/$(HOST)/config.nix
	SCRIPT=$$(nix eval --impure --raw --expr 'builtins.toFile "disk.sh" (import installer/prep-disk.nix { hostname = "$(HOST)"; config = (import configurations/$(HOST)/config.nix);})'); \
	bash -x $$SCRIPT

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
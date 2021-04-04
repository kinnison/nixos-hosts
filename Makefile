default: iso

clean:
	$(RM) result

iso:
	nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=installer/iso.nix && ls -lh result/iso/*

gc:
	nix-collect-garbage

disk: configurations/$(HOST)/config.nix
	SCRIPT=$$(nix eval --impure --raw --expr 'builtins.toFile "disk.sh" (import installer/prep-disk.nix { hostname = "$(HOST)"; config = (import configurations/$(HOST)/config.nix);})'); \
	bash -x $$SCRIPT

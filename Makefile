default: iso

clean:
	$(RM) result

iso:
	nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=installer/iso.nix && ls -lh result/iso/*

gc:
	nix-collect-garbage

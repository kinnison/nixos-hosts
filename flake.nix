# Top level flake for Daniel's NixOS host configuration

{
  description = "Daniel's host configurations";

  inputs = {
    # Basic inputs we need
    nixpkgs.url = "github:nixos/nixpkgs/nixos-20.09";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";

    # Stuff for home directory handling
    home-manager = {
      url = "github:nix-community/home-manager/release-20.09";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # We use sops for secrets handling
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Utility flake used for internal management
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs:
    let
      make-nixos-system = { sysconfig, nixpkgs, system, modules ? [] }:
        let
          overlays = [
            (
              final: prev: {
                unstable = import inputs.nixpkgs-unstable {
                  inherit system;
                };
              }
            )
          ];
        in
          nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [
              (import ./configurations sysconfig)
              inputs.sops-nix.nixosModules.sops
              inputs.home-manager.nixosModules.home-manager
              (
                { config, ... }: {
                  nixpkgs.overlays = overlays;
                  home-manager.useGlobalPkgs = false;
                  home-manager.useUserPackages = true;
                  #home-manager.users."${sysconfig.username}" = ...
                }
              )
            ] ++ modules;

            # extraModules = [ (import ./modules) ];
          };
      loadConfig = hostname: let
        config = import (./configurations + "/${hostname}" + /config.nix);
      in
        config // {
          hostname = hostname;
        };
    in
      {
        nixosConfigurations = {
          installer = let
            nixpkgs = inputs.nixpkgs;
          in
            nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              modules = [
                "${nixpkgs.outPath}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
                "${nixpkgs.outPath}/nixos/modules/installer/cd-dvd/channel.nix"
                inputs.sops-nix.nixosModules.sops
                ./installer/iso.nix
              ];
            };
          test = make-nixos-system {
            sysconfig = loadConfig "test";
            nixpkgs = inputs.nixpkgs;
            system = "x86_64-linux";
            modules = [
              (import ./configurations/test)
            ];
          };
        };
      }
      // (
        inputs.flake-utils.lib.eachDefaultSystem (
          system:
            let
              pkgs = inputs.nixpkgs.legacyPackages.${system};
              sops-pkgs = inputs.sops-nix.packages.${system};
            in
              {
                devShell = pkgs.mkShell {
                  buildInputs = with pkgs; with sops-pkgs; [ nixfmt sops-init-gpg-key ];
                  nativeBuildInputs = with sops-pkgs; [ sops-pgp-hook ];
                  sopsPGPKeyDirs = [ "./keys/hosts/" "./keys/users/" ];
                };
              }
        )
      );
}

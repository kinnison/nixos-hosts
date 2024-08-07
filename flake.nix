# Top level flake for Daniel's NixOS host configuration

{
  description = "Daniel's host configurations";

  inputs = {
    # Basic inputs we need
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";

    # Stuff for home directory handling
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # We use sops for secrets handling
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Utility flake used for internal management
    flake-utils.url = "github:numtide/flake-utils";

    # My dotfiles
    dotfiles = {
      url = "github:kinnison/dotfiles";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.nixpkgs-unstable.follows = "nixpkgs-unstable";
      inputs.flake-utils.follows = "flake-utils";
    };
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
                  # Use the flakes' nixpkgs for commands
                  nix = {
                    nixPath = [ "nixpkgs=${nixpkgs}" ];
                    registry.nixpkgs = {
                      from = {
                        id = "nixpkgs";
                        type = "indirect";
                      };
                      flake = nixpkgs;
                    };
                  };

                  nixpkgs.overlays = overlays;
                  home-manager.useGlobalPkgs = false;
                  home-manager.useUserPackages = true;
                  home-manager.users."${sysconfig.user.name}" =
                    (inputs.dotfiles.homeConfigurations.${config.networking.hostName} config);
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
                (
                  { ... }: {
                    nixpkgs.overlays = [
                      (
                        final: prev: {
                          installer = (import ./installer/pkgs { pkgs = prev; });
                        }
                      )
                    ];
                  }
                )
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
          parasomnix = make-nixos-system {
            sysconfig = loadConfig "parasomnix";
            nixpkgs = inputs.nixpkgs;
            system = "x86_64-linux";
            modules = [
              (import ./configurations/parasomnix)
            ];
          };
          indolence = make-nixos-system {
            sysconfig = loadConfig "indolence";
            nixpkgs = inputs.nixpkgs;
            system = "x86_64-linux";
            modules = [
              (import ./configurations/indolence)
            ];
          };
          cataplexy = make-nixos-system {
            sysconfig = loadConfig "cataplexy";
            nixpkgs = inputs.nixpkgs;
            system = "x86_64-linux";
            modules = [
              (import ./configurations/cataplexy)
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
                  buildInputs = with pkgs; with sops-pkgs; [ pwgen nixfmt-classic sops-init-gpg-key ];
                  nativeBuildInputs = with sops-pkgs; [ sops-import-keys-hook ];
                  sopsPGPKeyDirs = [ "./keys/hosts/" "./keys/users/" ];
                };
              }
        )
      );
}

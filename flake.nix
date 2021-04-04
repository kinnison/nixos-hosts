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
              (import ./configurations)
              (
                { config, ... }: {
                  nixpkgs.overlays = overlays;
                  home-manager.useGlobalPkgs = false;
                  home-manager.useUserPackages = true;
                  # home-manager.users.username = ...
                }
              )
            ] ++ modules;

            # extraModules = [ (import ./modules) ];
          };
    in
      {
        nixosConfigurations = {
          test = make-nixos-system {
            sysconfig = (import ./configurations/test/config.nix);
            nixpkgs = inputs.nixpkgs;
            system = "x86_64-linux";
          };
        };
      };
}

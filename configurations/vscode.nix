{ pkgs, ... }:
let
  extensions = (
    with pkgs.vscode-extensions; [
      bbenoist.Nix
      ms-vscode-remote.remote-ssh
    ]
  ) ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [];
  vscode-with-extensions = pkgs.vscode-with-extensions.override {
    vscodeExtensions = extensions;
  };
in
{
  # Enabling vscode requires that we allow non-free
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = [
    vscode-with-extensions
  ];
}

{
  description = "NixOS module which provides NVIDIA vGPU functionality";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      importPinned = path: args:
        { config, ... }: import path args
          {
            inherit (import nixpkgs
              {
                system = "x86_64-linux";
                config.allowUnfree = true;
              }) pkgs lib;
            inherit config inputs;
          };
      nixosModule = guest: importPinned ./default.nix { inherit guest; };
    in
    {
      nixosModules = {
        host = (nixosModule false);
        guest = (nixosModule true);
      };
    };
}

{
  description = "NixOS module which provides NVIDIA vGPU functionality";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    nixosModule = guest: import ./default.nix { inherit inputs guest; };
  in {
    nixosModules = {
      host = (nixosModule false);
      guest = (nixosModule true);
    };
  };
}

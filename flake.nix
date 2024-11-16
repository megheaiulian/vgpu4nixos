{
  description = "NixOS module which provides NVIDIA vGPU functionality";

  inputs = {
    # a working revision (29/08/2024)
    nixpkgs.url = "https://github.com/NixOS/nixpkgs/archive/54fee3a7e34a613aabc6dece34d5b7993183369c.tar.gz";
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

{
  description = "NixOS config for Honor MagicBook X14 Pro";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    # === NixOS Configuration ===
    nixosConfigurations.honor = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./configuration.nix
      ];
    };

    # === Dev Shells ===
    # Usage: nix develop .#picodata
    devShells.${system} = {
      picodata = import ./shells/picodata.nix { inherit pkgs; };
      default = self.devShells.${system}.picodata;
    };
  };
}

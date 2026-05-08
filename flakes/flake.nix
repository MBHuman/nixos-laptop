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
    # Usage:
    #   nix develop .#picodata
    #   nix develop .#python
    #   nix develop .#rust
    #   nix develop .#g1        (Python + Rust combined)
    devShells.${system} = {
      picodata    = import ./shells/picodata.nix    { inherit pkgs; };
      python      = import ./shells/python.nix      { inherit pkgs; };
      rust        = import ./shells/rust.nix        { inherit pkgs; };
      g1 = import ./shells/g1.nix { inherit pkgs; };
      default     = self.devShells.${system}.picodata;
    };
  };
}

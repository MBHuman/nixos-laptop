{
  description = "NixOS config for Honor MagicBook X14 Pro";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    hyprland = {
      url = "github:hyprwm/Hyprland";
      # Optional: pin to a specific commit or tag
      # url = "github:hyprwm/Hyprland?ref=v0.45.0";
    };
  };

  outputs = { self, nixpkgs, hyprland, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    # === NixOS Configuration ===
    nixosConfigurations.honor = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
        hyprland.nixosModules.default
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
{
  description = "NixOS laptop — dev shells entry point";

  inputs.flakes.url = "path:./flakes";

  outputs = { self, flakes, ... }:
    {
      devShells = flakes.devShells;
    };
}
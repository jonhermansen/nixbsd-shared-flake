{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
  };

  outputs = { nixpkgs, ... }: {
    nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
      ];
    };
  };
}

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    nixbsd.url = "github:jonhermansen/nixbsd/main";
  };

  outputs = { nixpkgs, nixbsd, ... }: 
  let
    system = "x86_64-linux";
    
    # Build a standalone derivation with just the bootloader files
    # This avoids infinite recursion by not referencing the full config
    nixbsdBootloader = nixbsd.packages.${system}.base.config.boot.loader.espContents;
  in
  {
    # Expose the bootloader as a separate package for easy building
    packages.${system}.nixbsd-bootloader = nixbsdBootloader;
    
    nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        # Pass the bootloader derivation path
        nixbsdBootloader = nixbsdBootloader;
      };
      modules = [
        ./configuration.nix
      ];
    };
  };
}

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
#    nixos-qubes = {
#      url = "git+file:../nixos-qubes?shallow=1";
#      inputs.nixpkgs.follows = "nixpkgs";
#    };
  };

  outputs = { nixpkgs, home-manager, stylix, nur, microvm, ... }: {
    nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        stylix.nixosModules.stylix
        ({ pkgs, ... }: {
          stylix.enable = true;
          stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/dracula.yaml";
        })
        nur.modules.nixos.default
        ({ pkgs, ... }: {
          environment.systemPackages = with pkgs.nur.repos.jonhermansen; [
            #davinci-resolve-studio
            flashrom-dasharo
            microvm.packages.${pkgs.stdenv.hostPlatform.system}.microvm
            spotx
          ];
        })
        #microvm.nixosModules.microvm
        #./stylix.nix
        #nixos-qubes.nixosModules.default
        #./nixos-qubes.nix
      ];
    };
  };
}

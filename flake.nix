{
  inputs.nixbsd.url = "github:jonhermansen/nixbsd/main";

  outputs = { nixbsd, ... }: 
  let
    system = "x86_64-linux";
    nixpkgs = nixbsd.inputs.nixpkgs;
    
    nixbsdSystem = nixbsd.lib.nixbsdSystem {
      modules = [{
        nixpkgs.hostPlatform = "x86_64-freebsd";
        nixpkgs.buildPlatform = "x86_64-linux";
        networking = { hostName = "nixbsd"; hostId = "a8f3d2c1"; };
        
        boot.supportedFilesystems = [ "zfs" ];
        boot.kernelModules = [ "zfs" ];  # Load ZFS module early
        boot.zfs.forceImportAll = true;  # JAH TODO: this is a hack
        boot.loader.stand-freebsd.enable = true;
        boot.copyKernelToBoot = true;
        boot.initmd.enable = true;
        boot.initmd.pivotFileSystems = [ "/" "/nix" ];
        
        users.users.root.initialPassword = "toor";
        
        fileSystems."/" = { 
          device = "tank/rootfs"; 
          fsType = "zfs"; 
        };
        fileSystems."/nix" = { 
          device = "tank/nix"; 
          fsType = "zfs"; 
        };
        fileSystems."/boot" = { 
          device = "/dev/msdosfs/ESP"; 
          fsType = "msdosfs"; 
        };
      }];
    };
    
  in {
    packages.${system}.zfsImage = nixpkgs.legacyPackages.${system}.callPackage "${nixpkgs}/nixos/lib/make-single-disk-zfs-image.nix" {
      config = (nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [{
          system.stateVersion = "26.05";
          networking.hostId = "a8f3d2c1";
          hardware.enableAllHardware = true;
          
          boot.supportedFilesystems = [ "zfs" ];
          boot.zfs.forceImportAll = true;
          boot.initrd.supportedFilesystems = [ "zfs" ];
          
          fileSystems."/" = { 
            fsType = "tmpfs"; 
            device = "tmpfs"; 
          };
          fileSystems."/nix" = { 
            device = "tank/nix"; 
            fsType = "zfs"; 
          };
          fileSystems."/boot" = { 
            device = "/dev/disk/by-label/ESP";
            fsType = "vfat"; 
          };
          
          boot.loader.grub = {
            enable = true;
            device = "/dev/vda";
            efiSupport = true;
            efiInstallAsRemovable = true;
            zfsSupport = true;
            default = 1;
            extraEntries = ''
              menuentry 'NixBSD' {
                insmod part_gpt
                insmod fat
                search --set=root --label ESP
                chainloader /efi/nixbsd/loader.efi
              }
            '';
          };
          
          services.getty.autologinUser = "nixos";
          users.users.root.initialPassword = "toor";
          users.users.nixos = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
            initialPassword = "nixos";
          };
          security.sudo.wheelNeedsPassword = false;
          
          system.extraDependencies = [ 
            nixbsdSystem.config.system.build.toplevel 
            nixbsdSystem.config.boot.initmd.image
          ];
        }];
      }).config;
      
      memSize = 4096;
      rootSize = 8192;
      rootPoolName = "tank";
      rootPoolProperties = { cachefile = "none"; autoexpand = "on"; };
      datasets."tank/nix".mount = "/nix";
      includeChannel = false;
      
      contents = [
        { 
          source = nixbsdSystem.config.system.build.toplevel; 
          target = "/nix/store"; 
        }
      ];
      
      postVM = ''
        export PATH=${nixpkgs.legacyPackages.${system}.mtools}/bin:${nixpkgs.legacyPackages.${system}.coreutils}/bin:$PATH
        
        img="$rootDiskImage@@2M"
        nixbsd_esp="${nixbsdSystem.config.boot.loader.espContents}"
        
        echo "=== Copying NixBSD bootloader files to ESP ==="
        
        # Create directory structure
        mmd -i "$img" ::/efi/nixbsd
        mmd -i "$img" ::/boot
        mmd -i "$img" ::/boot/lua
        mmd -i "$img" ::/boot/defaults
        
        # Copy NixBSD loader
        echo "Copying loader.efi..."
        mcopy -oi "$img" "$nixbsd_esp/efi/boot/bootx64.efi" ::/efi/nixbsd/loader.efi
        
        # Copy Lua files
        echo "Copying Lua files..."
        cd "$nixbsd_esp/boot/lua"
        for file in *; do
          mcopy -oi "$img" "$file" ::/boot/lua/
        done
        
        # Copy defaults
        echo "Copying defaults..."
        cd "$nixbsd_esp/boot/defaults"
        for file in *; do
          mcopy -oi "$img" "$file" ::/boot/defaults/
        done
        
        # Copy nixos directory with kernel and initmd
        echo "Copying kernel and boot files..."
        cd "$nixbsd_esp"
        
        # Create nixos directory structure
        mmd -i "$img" ::/nixos
        mmd -i "$img" ::/nixos/default
        mmd -i "$img" ::/nixos/default/kernel
        
        # Copy all kernel files (kernel executable and .ko modules)
        cd "$nixbsd_esp/nixos/default/kernel"
        for file in *; do
          if [ -f "$file" ]; then
            echo "  Copying kernel file: $file"
            mcopy -oi "$img" "$file" ::/nixos/default/kernel/
          fi
        done
        
        # Copy all files from nixos/default/ (includes initmd with hash in name)
        cd "$nixbsd_esp/nixos/default"
        for file in *; do
          if [ -f "$file" ]; then
            echo "  Copying: $file"
            mcopy -oi "$img" "$file" ::/nixos/default/
          fi
        done
        
        echo "=== ESP setup complete ==="
      '';
    };
  };
}

{
  inputs.nixbsd.url = "github:jonhermansen/nixbsd/main";

  outputs = { nixbsd, ... }: 
  let
    system = "x86_64-linux";
    nixpkgs = nixbsd.inputs.nixpkgs;

    # NixBSD system configuration
    nixbsdSystem = nixbsd.lib.nixbsdSystem {
      modules = [{
        nix.settings.experimental-features = [
          "ca-derivations"
          "flakes"
          "nix-command"
        ];
  
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

        documentation.enable = false;
        documentation.man.enable = false;
        
        users.users.root.initialPassword = "toor";
        users.users.nixos = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
          initialPassword = "nixos";
        };
        security.sudo.wheelNeedsPassword = false;
        
        fileSystems."/" = { 
          device = "tank/rootfs"; 
          fsType = "zfs";
          #options = [ "ro" ];
        };
        fileSystems."/nix" = { 
          device = "tank/nix"; 
          fsType = "zfs"; 
          #options = [ "ro" ];
        };
        fileSystems."/boot" = { 
          device = "/dev/msdosfs/ESP"; 
          fsType = "msdosfs"; 
          #options = [ "ro" ];
        };
      }];
    };
    
  in {
    packages.${system} = {
      # Primary build target: NixBSD system
      nixbsdSystem = nixbsdSystem.config.system.build.toplevel;
      
      # NixOS system (includes nixbsdSystem via extraDependencies)
      nixosSystem = (nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [{
            nix.settings.experimental-features = [
              "ca-derivations"
              "flakes"
              "nix-command"
            ];
    
            system.stateVersion = "26.05";
            networking.hostId = "a8f3d2c1";
            #hardware.enableAllHardware = true;
            
            boot.supportedFilesystems = [ "zfs" ];
            boot.zfs.forceImportAll = true;
            boot.initrd.supportedFilesystems = [ "zfs" ];
            
            documentation.enable = false;
            documentation.man.enable = false;
        
            fileSystems."/" = { 
              fsType = "tmpfs"; 
              device = "tmpfs"; 
            };
            fileSystems."/nix" = { 
              device = "tank/nix"; 
              fsType = "zfs"; 
              #options = [ "ro" ];
            };
            fileSystems."/boot" = { 
              device = "/dev/disk/by-label/ESP";
              fsType = "vfat"; 
              #options = [ "ro" ];
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
        }).config.system.build.toplevel;
      
      # Secondary build target: ZFS disk image (depends on nixosSystem which includes nixbsdSystem)
      zfsImage = nixpkgs.legacyPackages.${system}.callPackage "${nixpkgs}/nixos/lib/make-single-disk-zfs-image.nix" {
        config = (nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [{
            nix.settings.experimental-features = [
              "ca-derivations"
              "flakes"
              "nix-command"
            ];
    
            system.stateVersion = "26.05";
            networking.hostId = "a8f3d2c1";
            #hardware.enableAllHardware = true;
            
            boot.supportedFilesystems = [ "zfs" ];
            boot.zfs.forceImportAll = true;
            boot.initrd.supportedFilesystems = [ "zfs" ];
            
            documentation.enable = false;
            documentation.man.enable = false;
            
            fileSystems."/" = { 
              fsType = "tmpfs"; 
              device = "tmpfs"; 
            };
            fileSystems."/nix" = { 
              device = "tank/nix"; 
              fsType = "zfs"; 
              #options = [ "ro" ];
            };
            fileSystems."/boot" = { 
              device = "/dev/disk/by-label/ESP";
              fsType = "vfat"; 
              #options = [ "ro" ];
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

        bootSize = 320;   # ~335 MB actual
        rootSize = 1600;
        memSize = 2048;

        rootPoolName = "tank";
        rootPoolProperties = { cachefile = "none"; autoexpand = "off"; };
        rootPoolFilesystemProperties = {
          acltype = "posixacl";
          atime = "off";
          compression = "zstd-9";  # This replaces the default "on"
          mountpoint = "legacy";
          xattr = "sa";
        };
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
      
      # Make nixbsdSystem the default package
      default = nixbsdSystem.config.system.build.toplevel;
    };
  };
}

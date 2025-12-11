{
  config,
  lib,
  pkgs,
  nixbsdBootloader ? null,
  ...
}:

let
  # Create a script that copies NixBSD bootloader to ESP
  installNixBSD = lib.optionalString (nixbsdBootloader != null) ''
    # Copy NixBSD bootloader to ESP
    echo "Installing NixBSD bootloader..."
    mkdir -p /boot/efi/nixbsd
    cp -Lrf ${nixbsdBootloader}/* /boot/efi/nixbsd/
    echo "NixBSD bootloader installed to /boot/efi/nixbsd/"
  '';
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.grub.devices = [ "nodev" ];
  boot.loader.grub.enable = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.efiSupport = true;
  
  # Add activation script to copy NixBSD bootloader
  system.activationScripts.installNixBSD = lib.mkIf (nixbsdBootloader != null) {
    text = installNixBSD;
    deps = [];
  };
  
  boot.loader.grub.extraEntries = ''
    menuentry "NixBSD (FreeBSD)" {
      chainloader /efi/nixbsd/efi/boot/bootx64.efi
    }
    menuentry "FreeBSD (existing)" {
      chainloader /efi/boot/bootx64.efi.bak
    }
  '';

  environment.etc."sway/config.d/zzz-custom.conf".text = ''
    set $mod Mod1
  '';
  
  environment.systemPackages = with pkgs; [
    efibootmgr
    emacs
    foot
    git
    kitty
    mesa-demos
    nix-output-monitor
    nixfmt-rfc-style
    open-vm-tools
    pciutils
    usbutils
  ];
  
  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  
  networking.hostId = "12345678";
  networking.networkmanager.enable = true;
  
  nix.settings.experimental-features = [
    "flakes"
    "nix-command"
  ];
  
  nixpkgs.config.allowUnfree = true;
  
  programs.firefox.enable = true;
  programs.firefox.package = pkgs.librewolf;
  programs.fish.enable = true;
  programs.sway.enable = true;
  programs.sway.xwayland.enable = true;
  programs.virt-manager.enable = true;
  
  security.sudo.wheelNeedsPassword = false;
  
  services.getty.autologinUser = "user";
  services.sshd.enable = true;
  
  services.xserver.desktopManager.mate.enable = true;
  services.xserver.desktopManager.xfce.enable = true;
  services.xserver.displayManager.startx.enable = true;
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "vmware" ];
  services.xserver.windowManager.i3.enable = true;
  
  time.timeZone = "US/Eastern";
  
  users.users.user = {
    isNormalUser = true;
    extraGroups = [
      "libvirtd"
      "wheel"
    ];
    password = "password";
    shell = pkgs.fish;
  };
  
  virtualisation.vmware.guest.enable = true;
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };
}

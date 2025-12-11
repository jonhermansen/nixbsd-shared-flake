{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  #boot.loader.systemd-boot.configurationLimit = 5;
  #boot.loader.systemd-boot.edk2-uefi-shell.enable = true;
  #boot.loader.systemd-boot.enable = true;
  #boot.loader.systemd-boot.extraEntries."freebsd.conf" = ''
  #  title FreeBSD
  #  efi /EFI/BOOT/BOOTX64.EFI.BAK
  #  sort-key z_freebsd
  #'';
  #boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.devices = [ "nodev" ];
  boot.loader.grub.enable = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.extraEntries = ''
    menuentry "FreeBSD" {
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
    #lutris
    mesa-demos
    nix-output-monitor
    nixfmt-rfc-style
    open-vm-tools
    pciutils
    usbutils
    #wineWowPackages.waylandFull
    #wine64
    #wineWowPackages.stable
    #winetricks
  ];
  #environment.variables.WLR_NO_HARDWARE_CURSORS = "1";
  hardware.graphics.enable = true;
  networking.hostId = "12345678";
  networking.networkmanager.enable = true;
  nix.settings.experimental-features = [ "flakes" "nix-command" ];
  nixpkgs.config.allowUnfree = true;
  #programs.firefox.enable = true;
  #programs.firefox.package = pkgs.librewolf;
  programs.fish.enable = true;
  programs.sway.enable = true;
  programs.sway.xwayland.enable = true;
  programs.virt-manager.enable = true;
  security.sudo.wheelNeedsPassword = false;
  #services.desktopManager.gnome.enable = true;
  #services.desktopManager.plasma6.enable = true;
  #services.displayManager.gdm.enable = true;
  #services.displayManager.sddm.enable = true;
  services.getty.autologinUser = "user";
  #services.greetd.enable = true;
  #services.greetd.package = pkgs.tuigreet;
  #services.nfs.server.enable = true;
  #services.nfs.server.exports = ''
  #'';
  services.sshd.enable = true;
  services.xserver.desktopManager.mate.enable = true;
  services.xserver.desktopManager.xfce.enable = true;
  #services.xserver.displayManager.lightdm.enable = true;
  services.xserver.displayManager.startx.enable = true;
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "vmware" ];
  services.xserver.windowManager.i3.enable = true;
  time.timeZone = "US/Eastern";
  users.users.user = {
    isNormalUser = true;
    extraGroups = [ "libvirtd" "wheel" ];
    password = "password";
    shell = pkgs.fish;
  };
  virtualisation.vmware.guest.enable = true;
}

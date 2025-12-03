{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.limine.efiInstallAsRemovable = true;
  boot.loader.limine.enable = true;
  boot.loader.limine.enableEditor = true;
  #boot.loader.systemd-boot.enable = true;
  environment.etc."sway/config.d/zzz-custom.conf".text = ''
    set $mod Mod1
  '';
  environment.systemPackages = with pkgs; [
    efibootmgr
    emacs
    foot
    git
    kitty
    lutris
    nix-output-monitor
    open-vm-tools
    pciutils
    usbutils
    wineWowPackages.waylandFull
  ];
  environment.variables.WLR_NO_HARDWARE_CURSORS = "1";
  hardware.graphics.enable = true;
  networking.hostId = "12345678";
  networking.networkmanager.enable = true;
  nix.settings.experimental-features = [ "flakes" "nix-command" ];
  nixpkgs.config.allowUnfree = true;
  programs.sway.enable = true;
  security.sudo.wheelNeedsPassword = false;
  #services.desktopManager.gnome.enable = true;
  #services.displayManager.gdm.enable = true;
  services.getty.autologinUser = "user";
  #services.greetd.enable = true;
  #services.greetd.package = pkgs.tuigreet;
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
    extraGroups = [ "wheel" ];
    password = "password";
  };
  virtualisation.vmware.guest.enable = true;
  #virtualisation.vmware.host.enable = true;
}


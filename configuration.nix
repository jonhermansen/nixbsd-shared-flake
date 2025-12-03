{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.limine.enable = true;
  environment.systemPackages = with pkgs; [
    emacs-nox
    git
    nix-output-monitor
  ];
  networking.hostId = "12345678";
  networking.networkmanager.enable = true;
  programs.sway.enable = true;
  services.xserver.videoDrivers = [ "vmware" ];
  services.xserver.enable = true;
  services.xserver.windowManager.i3.enable = true;
  time.timeZone = "US/Eastern";
  users.users.user = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    password = "password";
  };
  virtualisation.vmware.guest.enable = true;
}


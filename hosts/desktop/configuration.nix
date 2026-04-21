# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      inputs.home-manager.nixosModules.default
      ../../modules/nixos/main-user.nix
      ../../modules/nixos/general.nix
      ../../modules/nixos/flatpak.nix
      ../../modules/nixos/gaming.nix
      ../../modules/nixos/wayland.nix
      ../../modules/nixos/gamedev.nix
      ../../modules/nixos/vr.nix
      ../../modules/nixos/airplay.nix
    ];

  # Flakeys
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Manually define kernel so it doesn't upgrade on its own. (Often causes problems)
  boot.kernelPackages = pkgs.linuxPackages_latest;
#   boot.kernelPackages = pkgs.linuxPackages_6_17;
  boot.supportedFilesystems = [ "ntfs" ];
  
  # Enable kernel ntsync support (have not tried yet)
  boot.kernelPatches = [    {
      name = "enable-ntsync";
      patch = null;
      structuredExtraConfig = with lib.kernel; {
        NTSYNC = module;  # Builds as loadable module (m=y equivalent)^5^^7^
      };
    }
  ];
  services.udev.extraRules = ''
    KERNEL=="ntsync", MODE="0666"
  '';

  networking.hostName = "nixos_desktop"; # Define your hostname.

  nix.settings = {
    substituters = ["https://nix-gaming.cachix.org"];
    trusted-public-keys = ["nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="];
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # QMK Keyboard shit
  hardware.keyboard.qmk.enable = true;
  services.udev.packages = with pkgs; [ via ];

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
#   main-user.enable = true;
#   main-user.userName = "matt";

  # Virtualbox
#   virtualisation.virtualbox.host.enable = true;
#   users.extraGroups.vboxusers.members = [ "matt" ];
#   nixpkgs.config.allowUnfree = true;
#   virtualisation.virtualbox.host.enableExtensionPack = true;

  users.users.matt = {
    isNormalUser = true;
    description = "matt";
    extraGroups = [ "networkmanager" "wheel" "adbusers" "kvm" "gamemode" ];
    packages = with pkgs; [
      ntfs3g
      via
      pkgs.android-tools
      pkgs.bazaar
      pkgs.winboat
    ];
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      "matt" = import ./home.nix;
    };
  };

  # Enable automatic login for the user.
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "matt";

  # Install firefox.
  programs.firefox.enable = false;

  # Shortcuts/Aliases
  programs.fish.shellAliases= {
      cat = "bat --paging=never";
      rebuild = "sudo nixos-rebuild switch --impure --flake ~/nixos/#nixos_desktop";
      upgrade = "sudo nixos-rebuild switch --impure --upgrade --flake ~/nixos/#nixos_desktop";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget

  environment.systemPackages = with pkgs; [
    kdePackages.kio-extras
    kdePackages.kwalletmanager
    kdePackages.wallpaper-engine-plugin
    eden
  ];

  # Mount matt-htpc home dir for easy editing.
  fileSystems."/mnt/matt-htpc" = {
  device = "matt-htpc@192.168.1.13:/home/matt-htpc/";
  fsType = "sshfs";
  options = [
    "nodev"
    "noatime"
    "allow_other"
    "IdentityFile=/home/matt/.ssh/id_rsa"
  ];
};
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}

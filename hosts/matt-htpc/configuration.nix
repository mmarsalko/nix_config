# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../modules/nixos/general.nix
    ];

  # Flakeys
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader.
#   boot.loader.systemd-boot.enable = true;
#   boot.loader.efi.canTouchEfiVariables = true;
#   boot.kernelPackages = pkgs.linuxPackages_latest;
#   boot.supportedFilesystems = [ "ntfs" ];

  # Bootloader (grub). This is the default when running in a VM..
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "matt-htpc"; # Define your hostname.
  networking.networkmanager.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
#   main-user.enable = true;
#   main-user.userName = "matt-htpc";
  users.users.matt-htpc = {
    isNormalUser = true;
    description = "matt-htpc";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      bat
      powerline-fonts
      fira-code-nerdfont
    ];
  };

  nixpkgs.config.allowUnfree = true;

  # Pulled from Nixos fish wiki. Launches fish from bash when in an interactive terminal
  # Recommended because fish being used as login shell is bad for POSIX reasons
  programs.starship = {
    enable = true;
    enableInteractive = true;
    enableFishIntegration = true;
  };
  programs.bash = {
  interactiveShellInit = ''
    if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
    then
      shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
      exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
    fi
  '';
  };
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      fastfetch
      starship init fish | source
      echo "Ctrl+Alt+S for git status"
      echo "Ctrl+Alt+F for file search"
    '';
    shellAliases= {
      cat = "bat --paging=never";
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos/#nixos_matt-htpc";
      upgrade = "sudo nixos-rebuild switch --upgrade --flake ~/nixos/#nixos_matt-htpc";
    };
  };
  programs.starship.presets = "gruvbox-rainbow";


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

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
  system.stateVersion = "25.11"; # Did you read the comment?

}

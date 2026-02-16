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
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.supportedFilesystems = [ "ntfs" ];

  # Bootloader (grub). This is the default when running in a VM..
#   boot.loader.grub.enable = true;
#   boot.loader.grub.device = "/dev/sda";
#   boot.loader.grub.useOSProber = true;

  networking.hostName = "matt-htpc"; # Define your hostname.
  networking.networkmanager.enable = true;
  networking.hosts = {
    "192.168.1.207" = [ "nasbox" ];
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
#   main-user.enable = true;
#   main-user.userName = "matt-htpc";
  users.users.matt-htpc = {
    isNormalUser = true;
    description = "matt-htpc";
    extraGroups = [ "networkmanager" "wheel" "docker" "video" "render" ];
    packages = with pkgs; [
      bat
      powerline-fonts
      starship
      fira-code-nerdfont
      docker-compose
      htop # move to general.nix later.
    ];
  };

  nixpkgs.config.allowUnfree = true;

  # Pulled from Nixos fish wiki. Launches fish from bash when in an interactive terminal
  # Recommended because fish being used as login shell is bad for POSIX reasons
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
    pkgs.cifs-utils # for cifs mounts
  ];

  environment.variables = {
    PLEX_ROOT = "/media/nas/plex";
    PLEX_TV_SERIES = "/media/nas/plex/tvseries";
    PLEX_MOVIES = "/media/nas/plex/movies";
    PLEX_UNSHARED = "/media/nas/plex/unshared";
    STARR_DOWNLOADS = "/run/media/matt-htpc/starr_downloads/downloads";
    STARR_INCOMPLETE = "/run/media/matt-htpc/starr_downloads/incomplete";
    WORKSPACE = "/home/matt-htpc/workspace";
  };

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      log-driver = "journald";
      storage-driver = "btrfs";
    };
    # NOTE: Can't access services on the network with rootless.
    # Just add matt-htpc to docker group instead (effectively root)
#     rootless = {
#       enable = true;
#       setSocketVariable = true;
#     };
  };

  # Create docker reverse proxy volume for containers to connect to.
  system.activationScripts.mkVPN = ''
  if ! ${pkgs.docker}/bin/docker network ls --format '{{.Name}}' | grep -q '^proxy$'; then
    ${pkgs.docker}/bin/docker network create proxy --subnet 172.40.0.0/16
  fi
  '';

  ## Networking magic so rootless docker has access to ports 0-1023
  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 8000 53 5300 ];
    allowedUDPPorts = [ 53 5300 ];
  };

  boot.kernel.sysctl = {
    "net.ipv4.conf.eth0.forwarding" = 1;    # enable port forwarding
  };

  networking = {
    firewall.extraCommands = ''
      iptables -A PREROUTING -t nat -i eth0 -p TCP --dport 80 -j REDIRECT --to-port 8000
      iptables -A PREROUTING -t nat -i eth0 -p TCP --dport 53 -j REDIRECT --to-port 5300
      iptables -A PREROUTING -t nat -i eth0 -p UDP --dport 53 -j REDIRECT --to-port 5300
    '';
  };

  ## Enable drivers for Intel Arc
  services.xserver.videoDrivers = [ "modesetting" ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      # Required for modern Intel GPUs (Xe iGPU and ARC)
      vpl-gpu-rt             # oneVPL (QSV) runtime (For transcoding)
      intel-compute-runtime  # OpenCL (NEO) + Level Zero for Arc/Xe (Optional Compute)
    ];
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";     # Prefer the modern iHD backend
  };

  # May help if FFmpeg/VAAPI/QSV init fails (esp. on Arc with i915):
  hardware.enableRedistributableFirmware = true;
  boot.kernelParams = [ "i915.enable_guc=3" ];

  ####### Filesystem mounts #######
  zramSwap.enable = true; # Download more RAM
  boot.supportedFilesystems = [ "nfs" "cifs"];
  services.rpcbind.enable = true; # required for NFS

  fileSystems."/media/nas/plex" = {
    device = "nasbox:/volume1/plex";
    fsType = "nfs";
    options = [ "defaults" ];
  };

  fileSystems."/media/nas/nextcloud" = {
    device = "nasbox:/volume1/nextcloud";
    fsType = "nfs";
    options = [ "defaults" ];
  };

  fileSystems."/media/nas/share" = {
    device = "//nasbox/share";
    fsType = "cifs";
    options = [
      "credentials=/home/matt-htpc/.smbcredentials"
      "vers=2.0"
      # I don't think I need uid/gid. If there are issues, turn them back on.
#       "uid=1000"
#       "gid=1000"
    ];
  };

  # Physical drive
  # NOTE: Enable me on real hardware!
  fileSystems."/media/matt-htpc/starr_downloads" = {
    device = "/dev/disk/by-uuid/954f20cb-54c7-4955-ba67-ebb42cea2ed1";
    fsType = "auto";
    options = [ "nosuid" "nodev" "nofail" "x-gvfs-show" "rw" ];
  };


  services.cron = {
    enable = true;
    mailto = "cron@shaffle.me";
    systemCronJobs = [
      "0 2 * * Tue root /opt/backup.sh"
      "0 1 * * * root /opt/restart_transmission.sh"
      "*/10 * * * * root /opt/dyndns.sh 2>&1 | logger -t matt_dyndns"
    ];
  };

  #####

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



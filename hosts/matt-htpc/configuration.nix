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

  networking.hostName = "matt-htpc"; # Define your hostname.
  networking.networkmanager.enable = true;
  networking.hosts = {
    "192.168.1.207" = [ "nasbox" ];
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.matt-htpc = {
    isNormalUser = true;
    description = "matt-htpc";
    extraGroups = [ "networkmanager" "wheel" "docker" "video" "render" ];
    packages = with pkgs; [
      bat
      powerline-fonts
      fira-code-nerdfont
      docker-compose
      htop # move to general.nix later.
    ];
  };

  nixpkgs.config.allowUnfree = true;

  # Shortcuts/Aliases
  programs.fish.shellAliases= {
      cat = "bat --paging=never";
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos/#nixos_matt-htpc";
      upgrade = "sudo nixos-rebuild switch --upgrade --flake ~/nixos/#nixos_matt-htpc";
    };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    pkgs.cifs-utils # for cifs mounts
    restic # for backups
  ];

  environment.variables = {
    PLEX_ROOT = "/media/nas/plex";
    PLEX_TV_SERIES = "/media/nas/plex/tvseries";
    PLEX_MOVIES = "/media/nas/plex/movies";
    PLEX_UNSHARED = "/media/nas/plex/unshared";
    STARR_DOWNLOADS = "/media/matt-htpc/starr_downloads/downloads";
    STARR_INCOMPLETE = "/media/matt-htpc/starr_downloads/incomplete";
    WORKSPACE = "/home/matt-htpc/workspace";
  };

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      log-driver = "journald";
      storage-driver = "btrfs";
    };
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
  zramSwap.enable = false; # Download more RAM
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

  # RESTIC BACKUP (btrfs snapshots) STORED AT /media/nas/htpc-backup/restic
  fileSystems."/media/nas/htpc-backup" = {
    device = "nasbox:/volume1/htpc-backup";
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
  fileSystems."/media/matt-htpc/starr_downloads" = {
    device = "/dev/disk/by-uuid/954f20cb-54c7-4955-ba67-ebb42cea2ed1";
    fsType = "auto";
    options = [ "nosuid" "nodev" "nofail" "x-gvfs-show" "rw" ];
  };

  # Mount the old 512GB drive. Will probably use this for something in the future
  fileSystems."/media/matt-htpc/ubuntu" = {
    device = "/dev/disk/by-uuid/f5d25ed5-728a-414f-9382-4caab0727cf1";
    fsType = "auto";
    options = [ "nosuid" "nodev" "nofail" "x-gvfs-show" "rw" ];
  };

  # BACKUP LOGIC:
  # Btrfs snapshot twice daily
  # Replicate to NAS once daily /w restic
  # NAS does cloud backup weekly
  services.cron = {
    enable = true;
    mailto = "cron@shaffle.me";
    systemCronJobs = [
      "0 6,18 * * * root /home/matt-htpc/nixos/hosts/matt-htpc/snapshot.sh"
      "0 2 * * * root /home/matt-htpc/nixos/hosts/matt-htpc/backup.sh"
      "*/10 * * * * root /home/matt-htpc/nixos/hosts/matt-htpc/dyndns.sh 2>&1 | logger -t matt_dyndns"
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



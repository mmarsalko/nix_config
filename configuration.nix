# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:
let
    nix-software-center = import (pkgs.fetchFromGitHub {
      owner = "snowfallorg";
      repo = "nix-software-center";
      rev = "0.1.2";
      sha256 = "xiqF1mP8wFubdsAQ1BmfjzCgOD3YZf7EGWl9i69FTls=";
    }) {};

#     old = import (fetchTarball {
#       url = "https://github.com/NixOS/nixpkgs/archive/1a817360a574b00d818fc096bce4b6c5c52ba718.tar.gz";
#       }) {};
#     vagrant-old = old.vagrant;
in


let
  discover-wrapped = pkgs.symlinkJoin
    {
      name = "discover-flatpak-backend";
      paths = [ pkgs.libsForQt5.discover ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/plasma-discover --add-flags "--backends flatpak"
      '';
    };
      unstable = import <nixos-unstable> {};

in

{
  ## Disable stable modules:
  disabledModules = [ "services/networking/tailscale.nix" ];

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./network-mounts.nix
      # Enable hibernation
      ./suspend-then-hibernate.nix
      ##sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos-unstable
      ## Add unstable modules:
      <nixos-unstable/nixos/modules/services/networking/tailscale.nix>
      <nixos-hardware/framework/16-inch/7040-amd>
#       <nixos-unstable/nixos/modules/services/desktop-managers/plasma6.nix>
#       <nixos-unstable/nixos/modules/programs/chromium.nix>

    ];

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_6_9;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Might resolve DNS issues on resume from suspend?
  networking.useNetworkd = true;
  systemd.network.enable = true;
  systemd.network.wait-online.enable = false;

  environment.variables = {
    VAGRANT_DEFAULT_PROVIDER = "libvirt";
  };

  # Enable bluetooth
  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot

  # Tell the system to boot from the swap device on resume from hibernation
  boot.resumeDevice = "/dev/nvme0n1p2";
  boot.initrd.systemd.enable = true;
  # Disable hibernation memory check (systemd bug workaround)
  systemd.services.systemd-logind.environment = {
    SYSTEMD_BYPASS_HIBERNATION_MEMORY_CHECK = "1";
  };

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";


  # platform and cpu options
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
#   services.xserver.desktopManager.plasma5.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Enable wayland
  services.xserver.displayManager.defaultSession = "plasma";

  # Laptop power management
  # It's claimed that ppd works better on AMD laptops, but my system has much better battery life
  # using tlp. Swap these if you experiencce otherwise.
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = true;
  powerManagement.enable = true;  # Enables hibernate?
  powerManagement.cpuFreqGovernor = "powersave";

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  # Enable trim for SSDs
  services.fstrim.enable = lib.mkDefault true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = false;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable fingerprint reader support
  services.fprintd.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.matt = {
    isNormalUser = true;
    description = "matt-lappy";
    extraGroups = [ "networkmanager" "wheel" "qemu-libvirtd" "libvirtd" ];
    packages = with pkgs; [
      kate
      fish
      htop
      ktailctl  # Tailscale GUI
#       unstable.ktailctl
#       vagrant-2.2.19
      libsForQt5.kcalc
      git
#       vagrant-old
      # Fixes the cursors
      (pkgs.runCommandLocal "breeze-cursors-fix" {} ''
        dir=$out/share/icons
        mkdir -p $dir
        ln -s ${breeze-qt5}/share/icons/breeze_cursors $dir/default
      '')
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;
  programs.kdeconnect.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    framework-tool
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    gparted
    usbutils # lsusb, etc
    nix-software-center
    pkgs.fprintd # Enables fingerprint reader
    discover-wrapped # Discover store (flatpak)
#     docker-compose

    # Vscode is a bit involved in order to get extensions working
    (vscode-with-extensions.override {
    vscodeExtensions = with vscode-extensions; [
      bbenoist.nix
      ms-python.python
      ms-azuretools.vscode-docker
      ms-vscode-remote.remote-ssh
    ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      {
        name = "remote-ssh-edit";
        publisher = "ms-vscode-remote";
        version = "0.47.2";
        sha256 = "1hp6gjh4xp2m1xlm1jsdzxw9d8frkiidhph6nvl24d0h8z34w49g";
      }
    ];
  })
  ];

  # Default plasma config comes with some stuff. Don't want these.
  environment.plasma5.excludePackages = with pkgs.libsForQt5; [
    plasma-browser-integration
  ];


  # Install mullvad & tailscale
  services.mullvad-vpn.enable = true;
  services.mullvad-vpn.package = pkgs.mullvad-vpn;
  networking.nameservers = [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];
  services.resolved = {
    enable = true;
    dnssec = "true";
    domains = [ "~." ];
    fallbackDns = [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];
    dnsovertls = "true";
  };

  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = "client";
  services.tailscale.package = unstable.tailscale;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;
  services.flatpak.enable = true;
#   services.touchegg.enable = true; # multi-touch gestures

  # Docker
#   virtualisation.docker.enable = true;
#   virtualisation.docker.storageDriver = "btrfs";
  # In case I need to store docker data outside of root
#   virtualisation.docker.daemon.settings = {
#     data-root = "/some-place/to-store-the-docker-data";
#   };

  # kvm for nixos dev:
  virtualisation.libvirtd.enable = true;
  boot.kernelModules = [ "kvm-amd" ];

  services.nfs.server.enable = true;
    # Add firewall exception for VirtualBox provider
  networking.firewall.extraCommands = ''
    ip46tables -I INPUT 1 -i vboxnet+ -p tcp -m tcp --dport 2049 -j ACCEPT
  '';

  # Add firewall exception for libvirt provider when using NFSv4
  networking.firewall.interfaces."virbr1" = {
    allowedTCPPorts = [ 2049 ];
    allowedUDPPorts = [ 2049 ];
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Follows an upgrade channel to get command hints.
  # I don't THINK this will actually auto-upgrade. I need to add more to the config for that.
  #   system.autoUpgrade.channel = "https://channels.nixos.org/nixos-23.11/";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}

{ config, pkgs, inputs, lib, ... }:

# This file is for stuff I always want on every machine.
{
  environment.systemPackages = with pkgs; [
    vim
    wget
    fastfetch
    xclip
    gparted
    usbutils
    vscode-fhs # Special version of vscode that can install extensions normally
    anydesk
    baobab
    unzip
    kdePackages.kate
    git
    appimage-run
    kdePackages.kcalc
    kdePackages.yakuake
    dconf-editor
    nix-index # allows nme to find who supplies an so file using eg: 'nix-locate --top-level libz.so.1'
    fd
    fishPlugins.fzf-fish
    fzf
    yt-dlp
    ffmpeg
    audacity
    distrobox
    distrobox-tui
    podman
    htop
    starship
#     winboat
    (python313.withPackages (python-pkgs: [
        python-pkgs.distro
        python-pkgs.pyudev
        python-pkgs.systemd-python
        python-pkgs.packaging
    ]))
  ];

  # Printing support
  services.printing.enable = true;
    services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # This enables AppImage support.
  programs.appimage.enable = true;
  programs.appimage.binfmt = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable networking
  networking.networkmanager.enable = true;

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

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # VM stuff
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  # Install mullvad
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

  # We like fish
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
  };
  programs.starship.enable = true;
  programs.starship.presets = [ "gruvbox-rainbow" ];

  services.fstrim.enable = lib.mkDefault true;  # SSD Trim#
  programs.kdeconnect.enable = true;

  # Enable bluetooth
  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot

#     system.activationScripts.iconTerminalSetup.text = ''
#     #!/usr/bin/env fish
#     source ${config.system.build.setEnvironment}
#     echo "Installing terminal icons.."
#     echo "XDG: $XDG_DATA_HOME"
#     echo "home: $HOME"
#     pushd ${icons-in-terminal}
#       ./install-autodetect.sh || true
#     popd
#   '';
}

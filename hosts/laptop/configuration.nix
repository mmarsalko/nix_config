{ config, pkgs, inputs, ... }:

let
      unstable = import <nixos-unstable> {};
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      inputs.home-manager.nixosModules.default
      ../../modules/nixos/main-user.nix
      ../../modules/nixos/general.nix
      ../../modules/nixos/flatpak.nix
      ../../modules/nixos/wayland.nix
      ../../modules/nixos/gamedev.nix

      ./kill-bluetooth-on-sleep.nix
      ./modules/nixos/network-mounts-tailscale.nix

      ## Add unstable modules:
      <nixos-unstable/nixos/modules/services/networking/tailscale.nix>
      <nixos-hardware/framework/16-inch/7040-amd>
    ];

    users.users.matt = {
        isNormalUser = true;
        description = "matt-lappy";
        extraGroups = [ "networkmanager" "wheel" ];
        shell = pkgs.bash;
        packages = with pkgs; [
            ktailctl  # Tailscale GUI
            acpica-tools
            # Fixes the cursors
            (pkgs.runCommandLocal "breeze-cursors-fix" {} ''
                dir=$out/share/icons
                mkdir -p $dir
                ln -s ${libsForQt5.breeze-qt5}/share/icons/breeze_cursors $dir/default
            '')
        ];
    };

    environment.systemPackages = with pkgs; [
        framework-tool
    ];
    programs.htop.enable = true;

    # Laptop power management
    # It's claimed that ppd works better on AMD laptops, but my system has much better battery life
    # using tlp. Swap these if you experiencce otherwise.
    services.power-profiles-daemon.enable = false;
    services.tlp.enable = true;
    powerManagement.enable = true;  # Enables hibernate?
    powerManagement.cpuFreqGovernor = "powersave";

    networking.hostName = "nixos"; # Define your hostname.
    networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

    # Might resolve DNS issues on resume from suspend?
    networking.useNetworkd = true;
    systemd.network.enable = true;
    systemd.network.wait-online.enable = false;

    # Tell the system to boot from the swap device on resume from hibernation
    boot.resumeDevice = "/dev/nvme0n1p2";
    boot.initrd.systemd.enable = true;
    # Disable hibernation memory check (systemd bug workaround)
    systemd.services.systemd-logind.environment = {
      SYSTEMD_BYPASS_HIBERNATION_MEMORY_CHECK = "1";
    };

    # For some reason, suspend-then-hibernate doesn't work without
    # Explicitly setting HibernateDelaySec myself.
    systemd.sleep.extraConfig = ''
        HibernateDelaySec=120m
        SuspendState=mem
    '';

    # platform and cpu options
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    # Set up tailscale (disable stable modules)
    disabledModules = [ "services/networking/tailscale.nix" ];
    services.tailscale.enable = true;
    services.tailscale.useRoutingFeatures = "client";
    services.tailscale.package = unstable.tailscale;

    system.stateVersion = "23.11"; # Did you read the comment?
}

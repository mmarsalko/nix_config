{ config, pkgs, inputs, ... }:

{
    hardware.graphics = {
        enable = true;
        enable32Bit = true;
    };

    # Enable amdgpu drivers
    boot.initrd.kernelModules = [ "amdgpu" ];
    services.xserver.enable = true;
    services.xserver.videoDrivers = ["amdgpu"];

    programs = {
        steam = {
            enable = true;
            remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
            dedicatedServer.openFirewall = true; # Open ports in the firewall for Source games
            gamescopeSession.enable = true;
        };
        gamescope = {
            enable = true;
            capSysNice = true;
        };
        gamemode.enable = true;
        obs-studio = {
            enable = true;
            enableVirtualCamera = true;
            plugins = with pkgs.obs-studio-plugins; [
                obs-backgroundremoval
                obs-pipewire-audio-capture
            ];
        };
    };

    # USB Connection for N64
    nixpkgs.config.packageOverrides = pkgs: {
        libftd2xx = pkgs.callPackage ./libftd2xx.nix { };
        unfloader = pkgs.callPackage ./unfloader.nix { };

    };
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
        stdenv.cc.cc.lib
        hidapi # needed for spacemouse in godot
        libftd2xx
    ];

#     nixpkgs.config.allowUnfree = true;
    environment.systemPackages = with pkgs; [
        mangohud
        protonup-qt
        lutris
        heroic
        bottles
        lact
        r2modman
        unfloader
        archipelago
#         poptracker
    ];

    # Let protonup-qt know where steam compat tools are.
    environment.sessionVariables = {
        STEAM_EXTRA_COMPAT_TOOLS_PATHS =
        "/home/matt/.steam/root/compatibilitytools.d";
    };

    # Add LACT for overclocking
    systemd.packages = with pkgs; [ lact ];
    systemd.services.lactd.wantedBy = ["multi-user.target"];
}

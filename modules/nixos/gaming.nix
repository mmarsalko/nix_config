{ config, pkgs, inputs, lib, ... }:

{
    hardware.graphics = {
        enable = true;
        enable32Bit = true;
    };

    boot.extraModulePackages = with config.boot.kernelPackages; [
        gcadapter-oc-kmod
    ];

    boot.kernelModules = lib.mkAfter [ "gcadapter-oc" ];

    # Enable amdgpu drivers
    boot.initrd.kernelModules = [ "amdgpu" ];
    services.xserver.enable = true;
    services.xserver.videoDrivers = ["amdgpu"];

    # Allows LACT to overclock the GPU
    boot.kernelParams = [
        "amdgpu.ppfeaturemask=0xffffffff"
    ];
    programs = {
        steam = {
            enable = true;
            remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
            dedicatedServer.openFirewall = true; # Open ports in the firewall for Source games
            gamescopeSession.enable = true;
        };
        gamescope = {
            enable = true;
            capSysNice = false;
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

    # ananicy is a workaround for capSysNice = true in gamescope.
    # games prefer gamescope -w 3440 -h 1440 -b -- %command%
    services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-cpp;
    extraRules = [
        {
            "name" = "gamescope";
            "nice" = -20;
        }
        ];
    };

    # USB Connection for N64
    nixpkgs.config.packageOverrides = pkgs: {
        libftd2xx = pkgs.callPackage ./libftd2xx.nix { };
        unfloader = pkgs.callPackage ./unfloader.nix { };
        wii-u-gc-adapter = pkgs.callPackage ./wii-u-gc-adapter.nix { };
    };

    # Install depends here for any programs not managed by nix
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
        stdenv.cc.cc.lib
        hidapi # needed for spacemouse in godot
        libftd2xx
        SDL2
        SDL2_ttf
        SDL2_image
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
        wii-u-gc-adapter
        archipelago
        winetricks
        protontricks
        xivlauncher
        game-devices-udev-rules
        parsec-bin
#         poptracker
    ];

    # This is needed for Slippi to run.
    programs.appimage.package = pkgs.appimage-run.override {
        extraPkgs = pkgs: [
        pkgs.curl
        pkgs.libmpg123
        ];
    };

    # Add slippi to launcher (expects appimage to be in ~/Games/Melee/)
    home-manager.users.matt = {
        xdg.desktopEntries.slippi-launcher = {
            name = "Slippi Launcher";
            comment = "Super Smash Bros. Melee netplay launcher";
            exec = "sh -c \"mullvad-exclude appimage-run ${config.users.users.matt.home}/Games/Melee/Slippi-Launcher-2.11.10-x86_64.AppImage & sleep 2 && xterm -e pkexec wii-u-gc-adapter\"";
            icon = "slippi-launcher";
            terminal = false;
            type = "Application";
            categories = [ "Game" ];
            startupNotify = true;
        };
        xdg.dataFile."icons/hicolor/scalable/apps/slippi-launcher.svg".source = ../../icons/slippi.svg;

    };
    # Let protonup-qt know where steam compat tools are.
    environment.sessionVariables = {
        STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/matt/.steam/root/compatibilitytools.d";
        PROTON_ENABLE_HIDRAW = "0x044f/0xb687,0x044f/0xb10a";
    };

    # Add LACT for overclocking
    systemd.packages = with pkgs; [ lact ];
    systemd.services.lactd.wantedBy = ["multi-user.target"];

    # Create a custom package for hotas udev rules
    services.udev.packages = [
    (pkgs.runCommand "60-hotas-rules" {} ''
        mkdir -p $out/lib/udev/rules.d
        cat > $out/lib/udev/rules.d/60-hotas.rules <<EOF
        # Hotas rules
        KERNEL=="hidraw*", ATTRS{idVendor}=="044f", ATTRS{idProduct}=="b687", MODE="0660", GROUP="users"
        KERNEL=="hidraw*", ATTRS{idVendor}=="044f", ATTRS{idProduct}=="b10a", MODE="0660", GROUP="users"
        EOF
        '')
    ];

    # Add Lossless Scaling (usage: LSFG_PROCESS=valheim %command%)
    # Check flake.nix for more info and github source
    services.lsfg-vk = {
        enable = true;
        ui.enable = true; # installs gui for configuring lsfg-vk
    };
}

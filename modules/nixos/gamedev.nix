{ config, pkgs, inputs, lib, ... }:

{
    # Create a wrapper script so godot has access to NIX_LD_LIBRARY_PATH (for hidapi access)
    environment.systemPackages = let
    godot-wrapped = pkgs.symlinkJoin {
        name = "godot_4_3-wrapped";
        paths = [
        (pkgs.writeShellScriptBin "godot_4_3" ''
            export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$NIX_LD_LIBRARY_PATH
            exec ${pkgs.godot_4_3}/bin/godot "$@"
        '')
        ];
        postBuild = ''
        mkdir -p $out/share/applications

        # Copy the desktop file from the original package
        cp ${pkgs.godot_4_3}/share/applications/*.desktop $out/share/applications/

        # Update the Exec line in the desktop file to point to our wrapped script
        sed -i "s|Exec=.*|Exec=$out/bin/godot_4_3|" $out/share/applications/*.desktop
        '';
    };
    in [
        godot-wrapped
        pkgs.godot_4_3
        pkgs.blender
        pkgs.code-cursor # ai IDE
        pkgs.toybox
    ];

    # Needed for spacemouse in blender
    hardware.spacenavd.enable = true;

    # Install build depends here for any programs not managed by nix (eg: steam-godot)
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
        hidapi # needed for spacemouse in godot
    ];


    programs.ssh.startAgent = true;


    # Create a custom package for high-priority spacemouse udev rules
    services.udev.packages = [
        (pkgs.runCommand "10-spacemouse-rules" {} ''
            mkdir -p $out/lib/udev/rules.d
            cat > $out/lib/udev/rules.d/10-spacemouse.rules << EOF
            # Spacenav 3D mouse rules
            KERNEL=="hidraw*", ATTRS{idVendor}=="256f", ATTRS{idProduct}=="c652", TAG+="uaccess"
            KERNEL=="hidraw*", ATTRS{idVendor}=="256f", ATTRS{idProduct}=="c63a", TAG+="uaccess"
            EOF
        '')
    ];
}

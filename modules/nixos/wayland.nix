{ config, pkgs, inputs, ... }:

{
    # Enable the X11 windowing system.
    # You can disable this if you're only using the Wayland session.
    services.xserver.enable = true;

    # Enable the KDE Plasma Desktop Environment.
    services.displayManager.sddm.enable = true;
    services.desktopManager.plasma6.enable = true;

    # This is where desktop-only apps should be added, to avoid bloat on headless servers.
    environment.systemPackages = with pkgs; [
        proton-pass
    ];
}

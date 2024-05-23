# NixOS Config for Framework 16 laptop

hardware-configuration.nix should match your own hardware. configuration.nix and suspend-then-hibernate.nix should be portable to other systems. (Except network mounts)
  
## General Stuff
- KDE Plasma & Wayland
- Some magic to make suspend-to-hibernate work
- Dedicated swap partition (swap is necessary for hibernation)
- Touchegg to make touchpad gestures work
- tlp to double your battery life
- fprintd for the fingerprint reader
- Bluetooth
- Pipewire
- Cursor fix

## Stuff you might not want in your own config
- Tailscale
- Mullvad
- vscode
- nix-software-center (This thing kinda sucks)
- flatpak (Good for apps that need to update requently, like discord and telegram

  

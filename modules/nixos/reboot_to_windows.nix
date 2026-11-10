{ config, pkgs, ... }:

let
    rebootToWindows = pkgs.writeTextFile {
      name = "reboot-to-windows.desktop";
      destination = "/share/applications/reboot-to-windows.desktop";
      text = ''
        [Desktop Entry]
        Name=Reboot To Windows
        Exec=pkexec sh -c "/run/current-system/sw/bin/efibootmgr -n 0000 && systemctl reboot"
        Type=Application
        StartupNotify=false
        Icon=${pkgs.windows10-icons}/share/icons/windows10/scalable/places/ubuntu-logo.svg
      '';
    };
  in {
    environment.systemPackages = [ rebootToWindows ];
  }

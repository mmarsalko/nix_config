{ config, lib, pkgs, modulesPath, ... }:


{
  networking.hosts = { "fd7a:115c:a1e0::3501:c33e" = [ "synology" ]; };

  # Away from home? Turn off mullvad and switch to this IP:
#   networking.hosts = { "100.64.195.62" = [ "synology" ]; };
  ## Set up network mounts
  services.rpcbind.enable = true;
  fileSystems."/mnt/workspace_nas" = {
#     device = nasbox.tailb6588a.ts.net:/volume1/workspace_nas;
    device = "[synology]:/volume1/workspace_nas";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" ];  # Lazy mount -- fixes wifi/networking issues
  };

  fileSystems."/mnt/share" = {
#     device = nasbox.tailb6588a.ts.net:/volume1/share;
    device = "[synology]:/volume1/share";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" ];  # Lazy mount -- fixes wifi/networking issues
  };

  fileSystems."/mnt/plex" = {
#     device = nasbox.tailb6588a.ts.net:/volume1/share;
    device = "[synology]:/volume1/plex";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" ];  # Lazy mount -- fixes wifi/networking issues
  };
}

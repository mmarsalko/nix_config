{ config, lib, pkgs, modulesPath, ... }:

{
  ## Set up network mounts
  services.rpcbind.enable = true;
  fileSystems."/mnt/workspace_nas" = {
    device = nasbox.tailb6588a.ts.net:/volume1/workspace_nas;
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" ];  # Lazy mount -- fixes wifi/networking issues
  };

  fileSystems."/mnt/share" = {
    device = nasbox.tailb6588a.ts.net:/volume1/share;
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" ];  # Lazy mount -- fixes wifi/networking issues
  };
}

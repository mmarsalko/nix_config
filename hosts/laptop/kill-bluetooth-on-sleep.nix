{ config, pkgs, ... }:

{
  # Define the suspend service
  systemd.services.bluetooth-rfkill-suspend = {
    description = "Soft block Bluetooth on suspend/hibernate";
    before = [ "sleep.target" ];
    wantedBy = [ "suspend.target" "hibernate.target" "suspend-then-hibernate.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/run/current-system/sw/bin/rfkill block bluetooth";
      ExecStartPost = "/bin/sleep 3";
      RemainAfterExit = true;
    };
  };

  # Define the resume service
  systemd.services.bluetooth-rfkill-resume = {
    description = "Unblock Bluetooth on resume";
    after = [ "suspend.target" "hibernate.target" "suspend-then-hibernate.target" ];
    wantedBy = [ "suspend.target" "hibernate.target" "suspend-then-hibernate.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/run/current-system/sw/bin/rfkill unblock bluetooth";
    };
  };
}

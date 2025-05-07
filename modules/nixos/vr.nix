{ pkgs, ... }:

{
    services.monado = {
        enable = true;
        defaultRuntime = true;
    };
    
    systemd.user.services.monado.environment = {
        STEAMVR_LH_ENABLE = "1";
        XRT_COMPOSITOR_COMPUTE = "1";
        WMR_HANDTRACKING = "0";
        # XRT_COMPOSITOR_SCALE_PERCENTAGE = "120"; # For anti-aliasing
        # U_PACING_COMP_MIN_TIME_MS = "5"; # uncomment if stuttering
    };
    # Uncomment if it's stuttering
#     systemd.user.services.monado.environment = {};

    # Add this to the launch line in steamvr titles to use monado instead:
    # PRESSURE_VESSEL_FILESYSTEMS_RW=$XDG_RUNTIME_DIR/monado_comp_ipc %command%
    environment.systemPackages = with pkgs; [
        opencomposite
        wlx-overlay-s
    ];

    boot.kernelPatches = [{
        name = "beyondfix";
        patch = ./bigscreen_beyond.patch;
    }
    # {
    #     name = "amdgpu-ignore-ctx-privileges";
    #     patch = pkgs.fetchpatch {
    #         name = "cap_sys_nice_begone.patch";
    #         url = "https://github.com/Frogging-Family/community-patches/raw/master/linux61-tkg/cap_sys_nice_begone.mypatch";
    #         hash = "sha256-Y3a0+x2xvHsfLax/uwycdJf3xLxvVfkfDVqjkxNaYEo=";
    #     };
    # }
    ];

    # OpenVR configuration for user matt
    home-manager.users.matt = { 
        xdg.configFile."openxr/1/active_runtime.json".source = "${pkgs.monado}/share/openxr/1/openxr_monado.json";
        xdg.configFile."openvr/openvrpaths.vrpath".text = ''
        {
            "config" :
            [
            "~/.local/share/Steam/config"
            ],
            "external_drivers" : 
            [
                "/run/media/matt/4578532b-0faa-44cc-b0fb-ce0991329478/home/pop_desktop/steam_library/steamapps/common/Bigscreen Beyond Driver"
            ],
            "jsonid" : "vrpathreg",
            "log" :
            [
            "~/.local/share/Steam/logs"
            ],
            "runtime" :
            [
            "${pkgs.opencomposite}/lib/opencomposite"
            ],
            "version" : 1
        }
        '';
    };
}

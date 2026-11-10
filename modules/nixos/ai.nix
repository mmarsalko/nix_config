{ config, pkgs, inputs, ... }:
{
    environment.systemPackages = [
        pkgs.mcp-nixos
        pkgs.opencode-desktop
        pkgs.ollama-rocm
    ];

    nixpkgs.config.rocmSupport = true;


}

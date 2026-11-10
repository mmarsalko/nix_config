{ config, pkgs, inputs, ... }:
{
    environment.systemPackages = [
        pkgs.mcp-nixos
        pkgs.ollama-rocm
    ];

    nixpkgs.config.rocmSupport = true;


}

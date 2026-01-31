{ config, lib, pkgs, ... }:
{
  imports = [
    ./options.nix
    ./config.nix
  ];
}

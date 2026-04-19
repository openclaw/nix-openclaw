{ nix-steipete-tools }:
{ config, lib, ... }:

{
  config = lib.mkIf (config ? home-manager) {
    home-manager.sharedModules = [
      {
        _module.args.steipeteToolsInput = nix-steipete-tools;
        imports = [ ../home-manager/openclaw ];
      }
    ];
  };
}

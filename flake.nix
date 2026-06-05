{
  description = "nix-openclaw: declarative OpenClaw packaging";

  nixConfig = {
    extra-substituters = [ "https://cache.garnix.io" ];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-openclaw-tools.url = "github:openclaw/nix-openclaw-tools";
    qmd.url = "github:tobi/qmd/v2.1.0";
    qmd.inputs.flake-utils.follows = "flake-utils";
    qmd.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      home-manager,
      nix-openclaw-tools,
      qmd,
    }:
    let
      openclawToolPkgsFor =
        system:
        if nix-openclaw-tools ? packages && builtins.hasAttr system nix-openclaw-tools.packages then
          nix-openclaw-tools.packages.${system}
        else
          { };
      qmdPkgsFor =
        system:
        if qmd ? packages && builtins.hasAttr system qmd.packages then qmd.packages.${system} else { };
      overlay =
        final: prev:
        import ./nix/overlay.nix {
          openclawToolPkgs = openclawToolPkgsFor prev.stdenv.hostPlatform.system;
          qmdPkgs = qmdPkgsFor prev.stdenv.hostPlatform.system;
        } final prev;
      sourceInfoStable = import ./nix/sources/openclaw-source.nix;
      sourceInfoDogfood = import ./nix/sources/openclaw-dogfood-source.nix;
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
    in
    flake-utils.lib.eachSystem systems (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
        openclawToolPkgs = openclawToolPkgsFor system;
        qmdPkgs = qmdPkgsFor system;
        qmdPackage =
          if pkgs.stdenv.hostPlatform.isDarwin then
            openclawToolPkgs.qmd or null
          else
            qmdPkgs.qmd or qmdPkgs.default or null;
        packageSetStable = import ./nix/packages {
          pkgs = pkgs;
          sourceInfo = sourceInfoStable;
          openclawToolPkgs = openclawToolPkgs;
          inherit qmdPackage;
        };
        packageSetDogfood = import ./nix/packages {
          pkgs = pkgs;
          sourceInfo = sourceInfoDogfood;
          openclawToolPkgs = openclawToolPkgs;
          inherit qmdPackage;
        };
        runtimePluginPackageOutputs = pkgs.lib.mapAttrs' (
          id: package: pkgs.lib.nameValuePair "openclaw-runtime-plugin-${id}" package
        ) packageSetStable.openclawRuntimePlugins;
      in
      {
        formatter = pkgs.nixfmt-tree.override {
          settings = {
            global.excludes = [ "nix/generated/openclaw-config-options.nix" ];
          };
        };

        packages =
          (builtins.removeAttrs packageSetStable [ "openclawRuntimePlugins" ])
          // {
            default = packageSetStable.openclaw;
            openclaw-dogfood = packageSetDogfood.openclaw;
            openclaw-gateway-dogfood = packageSetDogfood.openclaw-gateway;
          }
          // runtimePluginPackageOutputs;

        apps = {
          openclaw = flake-utils.lib.mkApp { drv = packageSetStable.openclaw; };
        };

        checks =
          let
            stableChecks = {
              gateway = packageSetStable.openclaw-gateway;
              bin-surface = pkgs.callPackage ./nix/checks/openclaw-bin-surface.nix {
                openclawPackage = packageSetStable.openclaw;
              };
              package-contents = pkgs.callPackage ./nix/checks/openclaw-package-contents.nix {
                openclawGateway = packageSetStable.openclaw-gateway;
              };
              default-instance = pkgs.callPackage ./nix/checks/openclaw-default-instance.nix { };
              runtime-plugin-locks = pkgs.callPackage ./nix/checks/openclaw-runtime-plugin-locks.nix { };
              workspace-materializer = pkgs.callPackage ./nix/checks/openclaw-workspace-materializer.nix { };
              config-validity = pkgs.callPackage ./nix/checks/openclaw-config-validity.nix {
                openclawGateway = packageSetStable.openclaw-gateway;
              };
              gateway-smoke = pkgs.callPackage ./nix/checks/openclaw-gateway-smoke.nix {
                openclawGateway = packageSetStable.openclaw-gateway;
              };
            }
            // pkgs.lib.optionalAttrs (qmdPackage != null) {
              qmd-runtime = pkgs.callPackage ./nix/checks/openclaw-qmd-runtime.nix {
                openclawPackage = packageSetStable.openclaw;
                inherit qmdPackage;
              };
            };
            dogfoodChecks = {
              package-contents-dogfood = pkgs.callPackage ./nix/checks/openclaw-package-contents.nix {
                openclawGateway = packageSetDogfood.openclaw-gateway;
                requireAgentWorkspaceTemplates = false;
              };
            };
            runtimePluginChecks = {
              runtime-plugin-packages = pkgs.symlinkJoin {
                name = "openclaw-runtime-plugin-packages";
                paths = builtins.attrValues packageSetStable.openclawRuntimePlugins;
              };
            };
            linuxOnlyChecks = pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
              hm-activation = import ./nix/checks/openclaw-hm-activation.nix {
                inherit pkgs home-manager;
              };
            };
          in
          stableChecks
          // runtimePluginChecks
          // dogfoodChecks
          // linuxOnlyChecks
          // {
            # CI aggregator: prove the default package/config/apply path without
            # rebuilding every generated runtime plugin package on every push.
            # Exhaustive runtime plugin package builds remain available as the
            # explicit runtime-plugin-packages check.
            ci = pkgs.symlinkJoin {
              name = "nix-openclaw-ci";
              paths = [
                packageSetStable.openclaw
              ]
              ++ (builtins.attrValues stableChecks)
              ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux (builtins.attrValues linuxOnlyChecks);
            };
          };

        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.git
            pkgs.nixfmt-tree
            pkgs.nil
          ];
        };
      }
    )
    // {
      overlays.default = overlay;
      templates.agent-first = {
        path = ./templates/agent-first;
        description = "Agent-first Home Manager setup for OpenClaw through Nix.";
      };
      nixosModules.openclaw-gateway = import ./nix/modules/nixos/openclaw-gateway.nix;
      homeManagerModules.openclaw = import ./nix/modules/home-manager/openclaw.nix;
      darwinModules.openclaw = import ./nix/modules/darwin/openclaw.nix;
    };
}

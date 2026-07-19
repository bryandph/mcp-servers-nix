{
  config,
  lib,
  mkServerModule,
  ...
}:
let
  cfg = config.programs.kubernetes;
in
{
  imports = [
    (mkServerModule {
      name = "kubernetes";
      packageName = "kubernetes-mcp-server";
    })
  ];

  options.programs.kubernetes = {
    readOnly = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Expose only tools annotated as read-only.";
    };

    disableDestructive = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Disable tools annotated as destructive.";
    };

    kubeconfig = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Runtime path to the kubeconfig file. This is a string rather than a
        Nix path so credential-bearing kubeconfigs are not copied to the store.
      '';
    };

    toolsets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Toolsets to expose. An empty list uses the server defaults.";
    };
  };

  config.settings.servers = lib.mkIf cfg.enable {
    kubernetes.args =
      lib.optionals cfg.readOnly [ "--read-only" ]
      ++ lib.optionals cfg.disableDestructive [ "--disable-destructive" ]
      ++ lib.optionals (cfg.kubeconfig != null) [
        "--kubeconfig"
        cfg.kubeconfig
      ]
      ++ lib.optionals (cfg.toolsets != [ ]) [
        "--toolsets"
        (lib.concatStringsSep "," cfg.toolsets)
      ];
  };
}

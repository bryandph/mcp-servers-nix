{
  config,
  lib,
  mkServerModule,
  pkgs,
  ...
}:
let
  cfg = config.programs.gcloud;
  accessConfig = pkgs.writeText "gcloud-mcp-config.json" (
    builtins.toJSON (
      if cfg.allowCommands != [ ] then { allow = cfg.allowCommands; } else { deny = cfg.denyCommands; }
    )
  );
in
{
  imports = [
    (mkServerModule {
      name = "gcloud";
      packageName = "gcloud-mcp";
    })
  ];

  options.programs.gcloud = {
    allowCommands = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "gcloud command prefixes to allow in addition to the server's built-in restrictions.";
    };

    denyCommands = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional gcloud command prefixes to deny.";
    };

    logLevel = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "debug"
          "info"
          "warn"
          "error"
        ]
      );
      default = null;
      description = "Server log level.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.allowCommands == [ ] || cfg.denyCommands == [ ];
        message = "programs.gcloud.allowCommands and denyCommands cannot both be set";
      }
    ];

    programs.gcloud.env = lib.mkIf (cfg.logLevel != null) {
      LOG_LEVEL = lib.mkDefault cfg.logLevel;
    };

    settings.servers.gcloud.args = lib.mkIf (cfg.allowCommands != [ ] || cfg.denyCommands != [ ]) [
      "--config"
      accessConfig
    ];
  };
}

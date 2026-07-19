{
  config,
  lib,
  mkServerModule,
  ...
}:
let
  cfg = config.programs.azure;
in
{
  imports = [
    (mkServerModule {
      name = "azure";
      packageName = "azure-mcp-server";
    })
  ];

  options.programs.azure = {
    cloud = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Azure cloud name, such as AzureCloud or AzureUSGovernment.";
    };

    telemetry = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable Microsoft telemetry collection.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.azure.env.AZURE_MCP_COLLECT_TELEMETRY_MICROSOFT = lib.mkDefault (
      if cfg.telemetry then "true" else "false"
    );

    programs.azure.args = [
      "server"
      "start"
    ]
    ++ lib.optionals (cfg.cloud != null) [
      "--cloud"
      cfg.cloud
    ];
  };
}

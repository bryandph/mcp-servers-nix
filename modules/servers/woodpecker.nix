{
  config,
  lib,
  mkServerModule,
  ...
}:
let
  cfg = config.programs.woodpecker;
in
{
  imports = [
    (mkServerModule {
      name = "woodpecker";
      packageName = "woodpecker-ci-mcp";
    })
  ];

  options.programs.woodpecker.serverUrl = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "Woodpecker CI server URL. Supply the token through envFile or passwordCommand.";
  };

  config = lib.mkIf cfg.enable {
    programs.woodpecker.args = [ "serve" ];
    programs.woodpecker.env = lib.mkIf (cfg.serverUrl != null) {
      WOODPECKER_MCP_WOODPECKER_URL = lib.mkDefault cfg.serverUrl;
    };
  };
}

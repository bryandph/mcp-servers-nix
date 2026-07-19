{
  config,
  lib,
  mkServerModule,
  ...
}:
let
  cfg = config.programs.aws-api;
in
{
  imports = [
    (mkServerModule {
      name = "aws-api";
      packageName = "aws-api-mcp-server";
    })
  ];

  options.programs.aws-api = {
    region = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Default AWS region. If null, use the normal AWS configuration chain.";
    };

    profile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "AWS profile name. If null, use the normal AWS credential chain.";
    };

    readOnly = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      description = "Restrict the server to AWS operations not classified as write operations.";
    };

    requireMutationConsent = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      description = "Require MCP elicitation consent before operations not classified as read-only.";
    };

    localFileAccess = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "no-access"
          "workdir"
          "unrestricted"
        ]
      );
      default = null;
      description = "Local file access allowed to AWS CLI operations.";
    };

    workingDirectory = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Runtime working directory for AWS CLI file operations. A string is
        used so mutable or credential-bearing directories never enter the Nix store.
      '';
    };

    telemetry = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      description = "Enable the server's additional AWS telemetry.";
    };
  };

  config.programs.aws-api.env = lib.mkMerge [
    (lib.mkIf (cfg.region != null) { AWS_REGION = lib.mkDefault cfg.region; })
    (lib.mkIf (cfg.profile != null) { AWS_API_MCP_PROFILE_NAME = lib.mkDefault cfg.profile; })
    (lib.mkIf (cfg.readOnly != null) {
      READ_OPERATIONS_ONLY = lib.mkDefault (if cfg.readOnly then "true" else "false");
    })
    (lib.mkIf (cfg.requireMutationConsent != null) {
      REQUIRE_MUTATION_CONSENT = lib.mkDefault (if cfg.requireMutationConsent then "true" else "false");
    })
    (lib.mkIf (cfg.localFileAccess != null) {
      AWS_API_MCP_ALLOW_UNRESTRICTED_LOCAL_FILE_ACCESS = lib.mkDefault cfg.localFileAccess;
    })
    (lib.mkIf (cfg.workingDirectory != null) {
      AWS_API_MCP_WORKING_DIR = lib.mkDefault cfg.workingDirectory;
    })
    (lib.mkIf (cfg.telemetry != null) {
      AWS_API_MCP_TELEMETRY = lib.mkDefault (if cfg.telemetry then "true" else "false");
    })
  ];
}

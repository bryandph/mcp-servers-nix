# Devenv adapter for mcp-servers-nix's declarative multi-flavor module system.
# Generated client files use devenv's managed-files lifecycle without taking
# ownership of unrelated client settings.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  mcp-lib = import ../lib;
  cfg = config.mcp-servers;

  flavorNames = [
    "claude-code"
    "codex"
    "opencode"
  ];

  flavorFormatMap = {
    claude-code = "json";
    codex = "toml";
    opencode = "json";
  };

  flavorFileMap = {
    claude-code = ".mcp.json";
    codex = ".codex/config.toml";
    opencode = "opencode.json";
  };

  mkFlavorConfig =
    flavor:
    let
      flavorCfg = cfg.flavors.${flavor};
      mergedConfig =
        lib.recursiveUpdate
          {
            inherit (cfg) programs settings;
          }
          {
            inherit (flavorCfg) programs settings;
          };
    in
    {
      inherit flavor;
      format = flavorFormatMap.${flavor};
    }
    // mergedConfig;

  mkFlavorOutput = flavor: mcp-lib.evalModule pkgs (mkFlavorConfig flavor);

  enabledFlavors = lib.filter (flavor: cfg.flavors.${flavor}.enable) flavorNames;

  extractPackages =
    evaluatedConfig:
    let
      programs = lib.filterAttrs (
        name: _: evaluatedConfig.config.programs.${name}.enable or false
      ) evaluatedConfig.config.programs;
    in
    lib.mapAttrsToList (_: value: value.package) programs;

  enabledPackages = lib.unique (
    lib.flatten (map (flavor: extractPackages (mkFlavorOutput flavor)) enabledFlavors)
  );
in
{
  options.mcp-servers = {
    programs = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Base MCP server program configuration applied to every enabled flavor.";
    };

    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = (pkgs.formats.json { }).type;
      };
      default = { };
      description = "Base freeform MCP configuration applied to every enabled flavor.";
    };

    flavors = lib.genAttrs flavorNames (
      flavor:
      lib.mkOption {
        type = lib.types.submodule {
          options = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = flavor == "claude-code";
              description = "Whether to manage the ${flavor} MCP configuration file.";
            };

            programs = lib.mkOption {
              type = lib.types.attrsOf lib.types.anything;
              default = { };
              description = "Program configuration recursively merged for ${flavor}.";
            };

            settings = lib.mkOption {
              type = lib.types.submodule {
                freeformType = (pkgs.formats.json { }).type;
              };
              default = { };
              description = "Freeform configuration recursively merged for ${flavor}.";
            };
          };
        };
        default = { };
        description = "MCP server configuration for ${flavor}.";
      }
    );

    configs = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      readOnly = true;
      description = "Generated configuration files for enabled flavors.";
    };

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      readOnly = true;
      description = "Packages used by MCP programs across enabled flavors.";
    };
  };

  config = {
    mcp-servers = {
      configs = lib.genAttrs enabledFlavors (flavor: (mkFlavorOutput flavor).config.configFile);
      packages = enabledPackages;
    };

    files = lib.listToAttrs (
      map (flavor: {
        name = flavorFileMap.${flavor};
        value.source = cfg.configs.${flavor};
      }) enabledFlavors
    );
  };
}

{ pkgs }:
let
  evaluated = pkgs.lib.evalModules {
    specialArgs = { inherit pkgs; };
    modules = [
      ../modules/devenv.nix
      {
        options.files = pkgs.lib.mkOption {
          type = pkgs.lib.types.attrsOf (
            pkgs.lib.types.submodule {
              options.source = pkgs.lib.mkOption {
                type = pkgs.lib.types.path;
              };
            }
          );
          default = { };
        };

        config.mcp-servers = {
          programs.filesystem = {
            enable = true;
            args = [ "." ];
          };
          flavors = {
            codex.enable = true;
            opencode.enable = true;
          };
        };
      }
    ];
  };
in
{
  test-devenv-module = pkgs.runCommand "test-devenv-module" { nativeBuildInputs = [ pkgs.jq ]; } ''
    jq -e '.mcpServers.filesystem.command | startswith("/nix/store/")' \
      ${evaluated.config.files.".mcp.json".source} >/dev/null

    jq -e '.mcp.filesystem.command[0] | startswith("/nix/store/")' \
      ${evaluated.config.files."opencode.json".source} >/dev/null

    grep -q '^\[mcp_servers.filesystem\]' \
      ${evaluated.config.files.".codex/config.toml".source}

    test "$(printf '%s\n' ${pkgs.lib.escapeShellArgs (builtins.attrNames evaluated.config.files)} | sort | tr '\n' ' ')" = \
      ".codex/config.toml .mcp.json opencode.json "

    touch $out
  '';
}

{ pkgs }:
let
  mcp-servers = import ../. { inherit pkgs; };
  evaluated = mcp-servers.lib.evalModule pkgs {
    programs.woodpecker = {
      enable = true;
      serverUrl = "https://woodpecker.invalid";
    };
  };
in
{
  test-woodpecker-module =
    pkgs.runCommand "test-woodpecker-module" { nativeBuildInputs = [ pkgs.jq ]; }
      ''
        jq -e '
          .mcpServers.woodpecker.command
          | startswith("/nix/store/")
        ' ${evaluated.config.configFile} >/dev/null

        jq -e '
          .mcpServers.woodpecker.args == ["serve"] and
          .mcpServers.woodpecker.env.WOODPECKER_MCP_WOODPECKER_URL == "https://woodpecker.invalid"
        ' ${evaluated.config.configFile} >/dev/null

        touch $out
      '';
}

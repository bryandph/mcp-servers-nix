{ pkgs }:
let
  mcp-servers = import ../. { inherit pkgs; };
  evaluated = mcp-servers.lib.evalModule pkgs {
    programs.opentofu.enable = true;
  };
in
{
  test-opentofu-module =
    pkgs.runCommand "test-opentofu-module" { nativeBuildInputs = [ pkgs.jq ]; }
      ''
        jq -e '
          .mcpServers.opentofu.command
          | startswith("/nix/store/")
        ' ${evaluated.config.configFile} >/dev/null

        jq -e '.mcpServers.opentofu.args == []' \
          ${evaluated.config.configFile} >/dev/null

        touch $out
      '';
}

{ pkgs }:
let
  mcp-servers = import ../. { inherit pkgs; };
  evaluated = mcp-servers.lib.evalModule pkgs {
    programs.gitea = {
      enable = true;
      host = "https://git.example.test";
      readOnly = true;
    };
  };
in
{
  test-gitea-module =
    pkgs.runCommand "test-gitea-module" { nativeBuildInputs = [ pkgs.jq ]; }
      ''
        jq -e '
          .mcpServers.gitea.command
          | startswith("/nix/store/")
        ' ${evaluated.config.configFile} >/dev/null

        jq -e '
          .mcpServers.gitea.args == [
            "-host",
            "https://git.example.test",
            "-read-only"
          ]
        ' ${evaluated.config.configFile} >/dev/null

        touch $out
      '';
}

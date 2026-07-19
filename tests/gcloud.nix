{ pkgs }:
let
  mcp-servers = import ../. { inherit pkgs; };
  evaluated = mcp-servers.lib.evalModule pkgs {
    programs.gcloud = {
      enable = true;
      allowCommands = [
        "projects describe"
        "compute instances list"
      ];
      logLevel = "warn";
    };
  };
in
{
  test-gcloud-module = pkgs.runCommand "test-gcloud-module" { nativeBuildInputs = [ pkgs.jq ]; } ''
    jq -e '
      .mcpServers.gcloud.command
      | startswith("/nix/store/")
    ' ${evaluated.config.configFile} >/dev/null

    jq -e '.mcpServers.gcloud.env == { LOG_LEVEL: "warn" }' \
      ${evaluated.config.configFile} >/dev/null

    config_path=$(jq -r '.mcpServers.gcloud.args[1]' ${evaluated.config.configFile})
    jq -e '.allow == ["projects describe", "compute instances list"]' "$config_path" >/dev/null

    touch $out
  '';
}

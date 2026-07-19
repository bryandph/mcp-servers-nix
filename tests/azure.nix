{ pkgs }:
let
  mcp-servers = import ../. { inherit pkgs; };
  passwordProvider = pkgs.writeShellScriptBin "azure-password-provider" ''
    printf '%s' "''${AZURE_TEST_SECRET:?}"
  '';
  evaluated = mcp-servers.lib.evalModule pkgs {
    programs.azure = {
      enable = true;
      cloud = "AzureUSGovernment";
      passwordCommand.AZURE_CLIENT_ID = [
        "${passwordProvider}/bin/azure-password-provider"
      ];
    };
  };
in
{
  test-azure-module = pkgs.runCommand "test-azure-module" { nativeBuildInputs = [ pkgs.jq ]; } ''
    jq -e '
      .mcpServers.azure.command
      | startswith("/nix/store/")
    ' ${evaluated.config.configFile} >/dev/null

    jq -e '.mcpServers.azure.args == ["server", "start", "--cloud", "AzureUSGovernment"]' \
      ${evaluated.config.configFile} >/dev/null

    jq -e '.mcpServers.azure.env.AZURE_MCP_COLLECT_TELEMETRY_MICROSOFT == "false"' \
      ${evaluated.config.configFile} >/dev/null

    ! grep -q 'AZURE_TEST_SECRET' ${evaluated.config.configFile}
    touch $out
  '';
}

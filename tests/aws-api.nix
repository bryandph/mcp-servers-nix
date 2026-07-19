{ pkgs }:
let
  mcp-servers = import ../. { inherit pkgs; };
  secretCommand = pkgs.writeShellScript "aws-api-secret" ''
    printf '%s\n' runtime-secret
  '';
  evaluated = mcp-servers.lib.evalModule pkgs {
    programs.aws-api = {
      enable = true;
      region = "us-east-2";
      readOnly = true;
      requireMutationConsent = true;
      localFileAccess = "no-access";
      telemetry = false;
      passwordCommand = {
        AWS_ACCESS_KEY_ID = [ "${secretCommand}" ];
      };
    };
  };
in
{
  test-aws-api-module = pkgs.runCommand "test-aws-api-module" { nativeBuildInputs = [ pkgs.jq ]; } ''
    jq -e '
      .mcpServers."aws-api".command
      | startswith("/nix/store/")
    ' ${evaluated.config.configFile} >/dev/null

    jq -e '
      .mcpServers."aws-api".env == {
        AWS_API_MCP_ALLOW_UNRESTRICTED_LOCAL_FILE_ACCESS: "no-access",
        AWS_API_MCP_TELEMETRY: "false",
        AWS_REGION: "us-east-2",
        READ_OPERATIONS_ONLY: "true",
        REQUIRE_MUTATION_CONSENT: "true"
      }
    ' ${evaluated.config.configFile} >/dev/null

    if grep -q runtime-secret ${evaluated.config.configFile}; then
      echo "passwordCommand output unexpectedly entered generated configuration" >&2
      exit 1
    fi

    touch $out
  '';
}

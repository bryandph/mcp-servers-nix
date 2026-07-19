{ pkgs }:
let
  mcp-servers = import ../. { inherit pkgs; };
  evaluated = mcp-servers.lib.evalModule pkgs {
    programs.kubernetes = {
      enable = true;
      readOnly = true;
      disableDestructive = true;
      kubeconfig = "/runtime/kubeconfig";
      toolsets = [
        "core"
        "config"
      ];
    };
  };
in
{
  test-kubernetes-module =
    pkgs.runCommand "test-kubernetes-module" { nativeBuildInputs = [ pkgs.jq ]; }
      ''
        jq -e '
          .mcpServers.kubernetes.command
          | startswith("/nix/store/")
        ' ${evaluated.config.configFile} >/dev/null

        jq -e '
          .mcpServers.kubernetes.args == [
            "--read-only",
            "--disable-destructive",
            "--kubeconfig",
            "/runtime/kubeconfig",
            "--toolsets",
            "core,config"
          ]
        ' ${evaluated.config.configFile} >/dev/null

        if grep -q 'kubeconfig.*content' ${evaluated.config.configFile}; then
          echo "kubeconfig content unexpectedly entered generated configuration" >&2
          exit 1
        fi

        touch $out
      '';
}

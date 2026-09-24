{ pkgs }:
let
  mcp-servers = import ../. { inherit pkgs; };
  evaluated = mcp-servers.lib.evalModule pkgs {
    programs.fluxcd-operator = {
      enable = true;
      readOnly = true;
      maskSecrets = false;
      namespace = "flux-system";
      kubeContext = "production";
    };
  };
in
{
  test-fluxcd-operator-module =
    pkgs.runCommand "test-fluxcd-operator-module" { nativeBuildInputs = [ pkgs.jq ]; }
      ''
        jq -e '
          .mcpServers."fluxcd-operator".command
          | startswith("/nix/store/")
        ' ${evaluated.config.configFile} >/dev/null

        jq -e '
          .mcpServers."fluxcd-operator".args == [
            "serve",
            "--read-only",
            "--mask-secrets=false",
            "--namespace",
            "flux-system",
            "--kube-context",
            "production"
          ]
        ' ${evaluated.config.configFile} >/dev/null

        touch $out
      '';
}

{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:

buildGoModule (finalAttrs: {
  pname = "woodpecker-ci-mcp";
  version = "0.0.1-unstable-2026-09-26";

  # Fork of denysvitali/woodpecker-ci-mcp carrying the environment-binding and
  # stdio-banner fixes plus the wait_for_pipeline tool.
  src = fetchFromGitHub {
    owner = "bryandph";
    repo = "woodpecker-ci-mcp";
    rev = "3ca70adf89c3b91e4ad19092ece6341d045a5414";
    hash = "sha256-uighcWEyzc45hBVfLPHtbLaq0FQNKws8xkOMKaJ4SuY=";
  };

  vendorHash = "sha256-4igF0PhiIBnzIxG4cJSc4jsiFTkiKAWZ5h924MIH8MA=";

  subPackages = [ "cmd/woodpecker-mcp" ];

  postInstall = ''
    env \
      WOODPECKER_MCP_WOODPECKER_URL=https://woodpecker.invalid \
      WOODPECKER_MCP_WOODPECKER_TOKEN=fixture-token \
      "$out/bin/woodpecker-mcp" config show > woodpecker-mcp-config-smoke
    grep -F "Woodpecker URL: https://woodpecker.invalid" woodpecker-mcp-config-smoke
    ! grep -F "Woodpecker Token: Not configured" woodpecker-mcp-config-smoke
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=branch=feat/wait-for-pipeline" ];
  };

  meta = {
    description = "MCP server for Woodpecker CI";
    homepage = "https://github.com/bryandph/woodpecker-ci-mcp";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "woodpecker-mcp";
  };
})

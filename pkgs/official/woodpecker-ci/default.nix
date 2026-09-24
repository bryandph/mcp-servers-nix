{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:

buildGoModule (finalAttrs: {
  pname = "woodpecker-ci-mcp";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "denysvitali";
    repo = "woodpecker-ci-mcp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-YyY1VkY2d2B2woH63IxKb9ffn7Kg0wP3EJSrkdPKOns=";
  };

  vendorHash = "sha256-4igF0PhiIBnzIxG4cJSc4jsiFTkiKAWZ5h924MIH8MA=";

  # v0.0.1 documents these variables but does not bind its nested Viper keys.
  # Keep runtime-only credentials usable until upstream fixes environment loading.
  postPatch = ''
    substituteInPlace internal/config/config.go \
      --replace-fail \
        $'v.SetEnvPrefix("WOODPECKER_MCP")\n\tv.AutomaticEnv()' \
        $'v.SetEnvPrefix("WOODPECKER_MCP")\n\tif err := v.BindEnv("woodpecker.url", "WOODPECKER_MCP_WOODPECKER_URL"); err != nil {\n\t\treturn nil, fmt.Errorf("failed to bind Woodpecker URL environment variable: %w", err)\n\t}\n\tif err := v.BindEnv("woodpecker.token", "WOODPECKER_MCP_WOODPECKER_TOKEN"); err != nil {\n\t\treturn nil, fmt.Errorf("failed to bind Woodpecker token environment variable: %w", err)\n\t}\n\tv.AutomaticEnv()'

    # MCP stdio reserves stdout for JSON-RPC. Redirect startup and error banners.
    substituteInPlace cmd/woodpecker-mcp/main.go \
      --replace-fail 'fmt.Println(titleStyle.Render("Starting Woodpecker MCP Server"))' 'fmt.Fprintln(os.Stderr, titleStyle.Render("Starting Woodpecker MCP Server"))' \
      --replace-fail 'fmt.Println(errorStyle.Render(fmt.Sprintf("Configuration error: %v", err)))' 'fmt.Fprintln(os.Stderr, errorStyle.Render(fmt.Sprintf("Configuration error: %v", err)))' \
      --replace-fail "fmt.Println(infoStyle.Render(\"Run 'woodpecker-mcp config init' to set up configuration\"))" "fmt.Fprintln(os.Stderr, infoStyle.Render(\"Run 'woodpecker-mcp config init' to set up configuration\"))" \
      --replace-fail 'fmt.Println(errorStyle.Render(fmt.Sprintf("Failed to connect to Woodpecker: %v", err)))' 'fmt.Fprintln(os.Stderr, errorStyle.Render(fmt.Sprintf("Failed to connect to Woodpecker: %v", err)))' \
      --replace-fail 'fmt.Println(successStyle.Render("MCP server started successfully"))' 'fmt.Fprintln(os.Stderr, successStyle.Render("MCP server started successfully"))' \
      --replace-fail 'fmt.Println(infoStyle.Render(fmt.Sprintf("Connected to Woodpecker server: %s", cfg.Woodpecker.URL)))' 'fmt.Fprintln(os.Stderr, infoStyle.Render(fmt.Sprintf("Connected to Woodpecker server: %s", cfg.Woodpecker.URL)))'
  '';

  subPackages = [ "cmd/woodpecker-mcp" ];

  postInstall = ''
    env \
      WOODPECKER_MCP_WOODPECKER_URL=https://woodpecker.invalid \
      WOODPECKER_MCP_WOODPECKER_TOKEN=fixture-token \
      "$out/bin/woodpecker-mcp" config show > woodpecker-mcp-config-smoke
    grep -F "Woodpecker URL: https://woodpecker.invalid" woodpecker-mcp-config-smoke
    ! grep -F "Woodpecker Token: Not configured" woodpecker-mcp-config-smoke
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "MCP server for Woodpecker CI";
    homepage = "https://github.com/denysvitali/woodpecker-ci-mcp";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "woodpecker-mcp";
  };
})

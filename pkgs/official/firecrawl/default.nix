{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  fetchPnpmDeps,
  pnpmConfigHook,
  pnpm_11,
  nodejs-slim,
  makeBinaryWrapper,
  nix-update-script,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "firecrawl-mcp";
  version = "3.29.1";

  # Upstream publishes npm releases without matching git tags after v3.24.1;
  # pin the commit whose package.json carries this version.
  src = fetchFromGitHub {
    owner = "firecrawl";
    repo = "firecrawl-mcp-server";
    rev = "7b6791faae3c7fefd18604fa5fcbd331d47dca73";
    hash = "sha256-Ojr6ibNMkCNB4rOuwYblZOWcOX6o8QZb6WMBmL2WDnE=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_11;
    fetcherVersion = 4;
    hash = "sha256-iokh3yIHCIPNYtboyQGlP7htFt88TZIOqRiqkXHIZ5Y=";
  };

  nativeBuildInputs = [
    nodejs-slim
    pnpmConfigHook
    pnpm_11
    makeBinaryWrapper
  ];

  buildPhase = ''
    runHook preBuild
    pnpm build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    rm -rf node_modules
    pnpm install --prod --offline --frozen-lockfile --ignore-scripts

    mkdir -p $out/bin $out/lib/firecrawl-mcp
    cp -r dist node_modules package.json $out/lib/firecrawl-mcp/

    makeBinaryWrapper ${nodejs-slim}/bin/node $out/bin/firecrawl-mcp \
      --add-flags "$out/lib/firecrawl-mcp/dist/index.js"

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };

  meta = {
    description = "MCP server for Firecrawl web scraping, cloud or self-hosted";
    homepage = "https://github.com/firecrawl/firecrawl-mcp-server";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "firecrawl-mcp";
  };
})

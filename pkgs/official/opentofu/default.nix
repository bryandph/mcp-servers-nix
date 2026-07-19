{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  fetchPnpmDeps,
  pnpmConfigHook,
  pnpm_10,
  nodejs-slim,
  makeBinaryWrapper,
  nix-update-script,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "opentofu-mcp-server";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "opentofu";
    repo = "opentofu-mcp-server";
    tag = "v${finalAttrs.version}";
    hash = "sha256-qgjAnoduzAjvxgbgG8QW53CMF3/bW0NQhDbVv3ebntw=";
  };

  # The v1.0.0 tag carries a pnpm 8 lockfile and floating dependency
  # specifiers. Use the mechanically migrated pnpm 10 lock and its matching
  # exact-version manifest so evaluation does not require vulnerable pnpm 8/9
  # releases and updates remain explicit.
  postPatch = ''
    cp ${./package.json} package.json
    cp ${./pnpm-lock.yaml} pnpm-lock.yaml
  '';

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_10;
    fetcherVersion = 3;
    postPatch = finalAttrs.postPatch;
    hash = "sha256-abz97iuymlaaqeym0uFtN50cZarQxxU25Mwr5Ft69bQ=";
  };

  nativeBuildInputs = [
    nodejs-slim
    pnpmConfigHook
    pnpm_10
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
    pnpm install --prod --offline --frozen-lockfile

    mkdir -p $out/bin $out/lib/opentofu-mcp-server
    cp -r dist node_modules package.json $out/lib/opentofu-mcp-server/

    makeBinaryWrapper ${nodejs-slim}/bin/node $out/bin/opentofu-mcp-server \
      --add-flags "$out/lib/opentofu-mcp-server/dist/local.js"

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "MCP server for accessing the OpenTofu Registry";
    homepage = "https://github.com/opentofu/opentofu-mcp-server";
    license = lib.licenses.mpl20;
    maintainers = [ ];
    mainProgram = "opentofu-mcp-server";
  };
})

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
  # exact-version manifest so updates remain explicit. Build with pnpm 11:
  # nixpkgs marks pnpm 8/9/10 insecure, and pnpm 11 reads the same lockfile.
  postPatch = ''
    cp ${./package.json} package.json
    cp ${./pnpm-lock.yaml} pnpm-lock.yaml
  '';

  # fetcherVersion 4 archives pnpm 11's store index as a sqlite3 .dump.
  # SQLite 3.53 dumps blobs as x'..' instead of X'..'; nixpkgs-unstable
  # reverts that (NixOS/nixpkgs@29ee10df315a) but nixos-26.05 ships sqlite
  # 3.53 without it. Apply the same revert here so the hash is the same on
  # both; it is a no-op where nixpkgs already normalizes. Drop this override
  # once nixos-26.05 carries the fix.
  pnpmDeps =
    (fetchPnpmDeps {
      inherit (finalAttrs) pname version src;
      pnpm = pnpm_11;
      fetcherVersion = 4;
      postPatch = finalAttrs.postPatch;
      hash = "sha256-KUPE/DKbGLsWwrSnLwTJ3EdC2JZWFCM8+A9g9vATot0=";
    }).overrideAttrs
      (old: {
        fixupPhase =
          let
            anchor = ''rm "$storePath/v11/index.db"'';
          in
          assert lib.assertMsg (lib.hasInfix anchor old.fixupPhase)
            "opentofu-mcp-server: fetchPnpmDeps fixupPhase no longer dumps index.db; revisit the sqlite normalization";
          builtins.replaceStrings
            [ anchor ]
            [
              ''
                ${anchor}
                sed -i "s/,x'/,X'/g" "$storePath/v11/index.db.sql"
              ''
            ]
            old.fixupPhase;
      });

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

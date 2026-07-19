{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  google-cloud-sdk,
  makeWrapper,
  nix-update-script,
  nodejs,
}:

buildNpmPackage (finalAttrs: {
  pname = "gcloud-mcp";
  version = "0.5.3";

  src = fetchFromGitHub {
    owner = "googleapis";
    repo = "gcloud-mcp";
    rev = "808746a7c63e4be9585f6da0cce4b813cecb95ed";
    hash = "sha256-36KjtqHJ5R+rSUPB27q01vODdnhX48KyC1WwWaeJx+s=";
  };

  npmDepsHash = "sha256-ALKRdLbxMOuIL54fsc8qwdPXkJ50YepfBS6tI02Xm7U=";

  nativeBuildInputs = [ makeWrapper ];

  buildPhase = ''
    runHook preBuild

    npm run build --workspace=@google-cloud/gcloud-mcp

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/gcloud-mcp
    cp packages/gcloud-mcp/dist/bundle.js $out/lib/gcloud-mcp/bundle.js

    makeWrapper ${nodejs}/bin/node $out/bin/gcloud-mcp \
      --add-flags "$out/lib/gcloud-mcp/bundle.js" \
      --prefix PATH : ${lib.makeBinPath [ google-cloud-sdk ]}

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version-regex"
      "gcloud-mcp-v(.*)"
    ];
  };

  meta = {
    description = "MCP server for interacting with Google Cloud through the gcloud CLI";
    homepage = "https://github.com/googleapis/gcloud-mcp";
    changelog = "https://github.com/googleapis/gcloud-mcp/releases/tag/gcloud-mcp-v${finalAttrs.version}";
    license = lib.licenses.asl20;
    mainProgram = "gcloud-mcp";
  };
})

{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
}:

let
  assets = {
    aarch64-linux = {
      name = "flux-operator-mcp_0.55.0_linux_arm64.tar.gz";
      hash = "sha256-npG044UvHG6qeqanUSB+gTQ+Nb9WAMQ/pL9dmxxgGRc=";
    };
    x86_64-linux = {
      name = "flux-operator-mcp_0.55.0_linux_amd64.tar.gz";
      hash = "sha256-UYYrBJNu9gabYxkdeOSZMsrIpyrv1auRUy8SsTRBKEw=";
    };
    aarch64-darwin = {
      name = "flux-operator-mcp_0.55.0_darwin_arm64.tar.gz";
      hash = "sha256-adpOlaDRywej7wtFN3hvmKQIlaUnp1jCOa8z6tMBNzY=";
    };
    x86_64-darwin = {
      name = "flux-operator-mcp_0.55.0_darwin_amd64.tar.gz";
      hash = "sha256-F+7YCQkr/X0VE0eNs5s2DYHBd9AbXEZZK3Fv7VJ3f9M=";
    };
  };
  asset = assets.${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "flux-operator-mcp";
  version = "0.55.0";

  src = fetchurl {
    url = "https://github.com/controlplaneio-fluxcd/flux-operator/releases/download/v${finalAttrs.version}/${asset.name}";
    inherit (asset) hash;
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    tar -xzf "$src"
    install -Dm755 flux-operator-mcp "$out/bin/flux-operator-mcp"
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/flux-operator-mcp" --help >/dev/null
    runHook postInstallCheck
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--use-github-releases" ];
  };

  meta = {
    description = "Model Context Protocol server for Flux Operator";
    homepage = "https://fluxoperator.dev/mcp-server/";
    license = lib.licenses.agpl3Only;
    maintainers = [ ];
    mainProgram = "flux-operator-mcp";
    platforms = builtins.attrNames assets;
  };
})

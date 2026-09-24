{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
}:

let
  assets = {
    aarch64-linux = {
      name = "flux-operator-mcp_0.60.0_linux_arm64.tar.gz";
      hash = "sha256-SOsnf6oZswODTgfDwRKJkzAseAebcSJzUkAyLGh8b/8=";
    };
    x86_64-linux = {
      name = "flux-operator-mcp_0.60.0_linux_amd64.tar.gz";
      hash = "sha256-DpuqMmPLDXoTvKzul5ZIpmmoKIQO9bQVv4HHfXHX820=";
    };
    aarch64-darwin = {
      name = "flux-operator-mcp_0.60.0_darwin_arm64.tar.gz";
      hash = "sha256-uc/Rhx/dkLbi9B8QoVRgLDofzL1VOjuMeOa7R2bL2D4=";
    };
    x86_64-darwin = {
      name = "flux-operator-mcp_0.60.0_darwin_amd64.tar.gz";
      hash = "sha256-BNH+TEzzCffX4D2taIKSD1YRZZg0qSctj/BhWWfy7a8=";
    };
  };
  asset = assets.${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "flux-operator-mcp";
  version = "0.60.0";

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

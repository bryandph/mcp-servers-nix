{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  unzip,
  patchelf,
  icu,
  openssl,
  zlib,
}:

let
  assets = {
    aarch64-linux = {
      name = "Azure.Mcp.Server-linux-arm64.zip";
      hash = "sha256-rn4H6vkc1eeEO/Jy2MEUk+JuQMBnbn1RvE/o80RxKBU=";
    };
    x86_64-linux = {
      name = "Azure.Mcp.Server-linux-x64.zip";
      hash = "sha256-GXPmHvGDrizKB911HyckJro3wKiYCZm0vcSKlgdzFOA=";
    };
    aarch64-darwin = {
      name = "Azure.Mcp.Server-osx-arm64.zip";
      hash = "sha256-c18HBzxMUkOpkwZF0LI9hu7AQ6JF2SM4TOifRqulvtk=";
    };
    x86_64-darwin = {
      name = "Azure.Mcp.Server-osx-x64.zip";
      hash = "sha256-JuITXHIS7RzX5MDCRSxMavRseLrZIpoKOBA4/d8UAAw=";
    };
  };
  asset = assets.${stdenvNoCC.hostPlatform.system};
  # The self-extracting bundle dlopens these at runtime; they are not in
  # the apphost's DT_NEEDED, so they must come in via LD_LIBRARY_PATH.
  runtimeLibs = lib.makeLibraryPath [
    stdenv.cc.cc.lib
    icu
    openssl
    zlib
  ];
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "azure-mcp-server";
  version = "2.0.5";

  src = fetchurl {
    url = "https://github.com/microsoft/mcp/releases/download/Azure.Mcp.Server-${finalAttrs.version}/${asset.name}";
    inherit (asset) hash;
  };

  nativeBuildInputs = [
    makeWrapper
    unzip
  ]
  ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [ patchelf ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  unpackPhase = ''
    runHook preUnpack
    unzip "$src"
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin" "$out/libexec/azure-mcp-server"
    cp -R . "$out/libexec/azure-mcp-server"
    chmod +x "$out/libexec/azure-mcp-server/azmcp"
  ''
  + lib.optionalString stdenvNoCC.hostPlatform.isLinux ''
    patchelf --set-interpreter ${stdenv.cc.bintools.dynamicLinker} \
      "$out/libexec/azure-mcp-server/azmcp"
  ''
  + ''
    makeWrapper "$out/libexec/azure-mcp-server/azmcp" "$out/bin/azmcp" \
      --run 'export DOTNET_BUNDLE_EXTRACT_BASE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/azure-mcp-server/dotnet-bundle"; mkdir -p "$DOTNET_BUNDLE_EXTRACT_BASE_DIR"' ${lib.optionalString stdenvNoCC.hostPlatform.isLinux "--prefix LD_LIBRARY_PATH : ${runtimeLibs}"}
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    export XDG_CACHE_HOME="$TMPDIR/cache"
    "$out/bin/azmcp" --version
    runHook postInstallCheck
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Azure MCP Server - Model Context Protocol implementation for Azure";
    homepage = "https://github.com/microsoft/mcp";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "azmcp";
    platforms = builtins.attrNames assets;
  };
})

{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:

buildGoModule (finalAttrs: {
  pname = "kubernetes-mcp-server";
  version = "0.0.67";

  src = fetchFromGitHub {
    owner = "containers";
    repo = "kubernetes-mcp-server";
    tag = "v${finalAttrs.version}";
    hash = "sha256-rejF9JsszB3ZirZhoK1VDbCH/P0Xzmh4TJw5j+okj+M=";
  };

  vendorHash = "sha256-TSB2jAWh2PlDHpvzA/rrBbjaR8sgyjivDO0vsbcuvgg=";

  subPackages = [ "cmd/kubernetes-mcp-server" ];

  ldflags = [
    "-s"
    "-w"
    "-X=github.com/containers/kubernetes-mcp-server/pkg/version.Version=v${finalAttrs.version}"
    "-X=github.com/containers/kubernetes-mcp-server/pkg/version.BinaryName=kubernetes-mcp-server"
    "-X=github.com/containers/kubernetes-mcp-server/pkg/version.WebsiteURL=https://github.com/containers/kubernetes-mcp-server"
  ];

  # Upstream's suite contains cluster and race-detector integration tests.
  doCheck = false;

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Model Context Protocol server for Kubernetes and OpenShift";
    homepage = "https://github.com/containers/kubernetes-mcp-server";
    license = lib.licenses.asl20;
    maintainers = [ ];
    mainProgram = "kubernetes-mcp-server";
  };
})

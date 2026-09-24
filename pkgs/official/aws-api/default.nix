{
  lib,
  fetchFromGitHub,
  awscli,
  python3Packages,
  writableTmpDirAsHomeHook,
}:

let
  fastmcp = import ./fastmcp.nix {
    inherit lib fetchFromGitHub python3Packages;
  };

  awscli-python = python3Packages.buildPythonPackage {
    pname = "awscli";
    inherit (awscli) version src;
    pyproject = true;

    build-system = [ python3Packages.setuptools ];

    pythonRelaxDeps = [
      "docutils"
      "rsa"
    ];

    dependencies = with python3Packages; [
      botocore
      colorama
      docutils
      pyyaml
      rsa
      s3transfer
    ];

    pythonImportsCheck = [ "awscli.clidriver" ];
  };
in
python3Packages.buildPythonApplication (finalAttrs: {
  pname = "aws-api-mcp-server";
  version = "1.5.5";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "awslabs";
    repo = "mcp";
    rev = "79267c6757781e8adc12e50c1920e30a8afe21dd";
    hash = "sha256-BsvhdUJppcNmdEsHSWRzqvnCwUiLZJ1fgewvx4uXY0Y=";
  };

  sourceRoot = "${finalAttrs.src.name}/src/aws-api-mcp-server";

  build-system = [ python3Packages.hatchling ];

  # The server pins the newest awscli release, while nixpkgs may lag slightly.
  # Keep the nixpkgs-managed CLI dependency set internally consistent.
  pythonRelaxDeps = [ "awscli" ];

  dependencies =
    (with python3Packages; [
      awscrt
      boto3
      botocore
      distro
      importlib-resources
      loguru
      lxml
      mcp
      pydantic
      python-frontmatter
      python-json-logger
      requests
      setuptools
    ])
    ++ [
      awscli-python
      fastmcp
    ];

  pythonImportsCheck = [ "awslabs.aws_api_mcp_server.server" ];

  nativeCheckInputs = [ writableTmpDirAsHomeHook ];

  meta = {
    description = "MCP server for interacting with AWS services through AWS CLI commands";
    homepage = "https://awslabs.github.io/mcp/servers/aws-api-mcp-server/";
    changelog = "https://github.com/awslabs/mcp/blob/main/src/aws-api-mcp-server/CHANGELOG.md";
    license = lib.licenses.asl20;
    mainProgram = "awslabs.aws-api-mcp-server";
  };
})

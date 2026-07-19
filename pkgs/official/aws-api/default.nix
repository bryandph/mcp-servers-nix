{
  lib,
  fetchFromGitHub,
  awscli,
  python3Packages,
  writableTmpDirAsHomeHook,
}:

let
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
  version = "1.3.5";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "awslabs";
    repo = "mcp";
    rev = "c816e7fa8729545d65e31043cff9c35892bd5dc7";
    hash = "sha256-CaRQ0uo+49rAp8J0Apbb0bYFOkvOZPvhruqr8+9R8qU=";
  };

  sourceRoot = "${finalAttrs.src.name}/src/aws-api-mcp-server";

  build-system = [ python3Packages.hatchling ];

  dependencies =
    (with python3Packages; [
      awscrt
      boto3
      botocore
      distro
      fastmcp
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
    ++ [ awscli-python ];

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

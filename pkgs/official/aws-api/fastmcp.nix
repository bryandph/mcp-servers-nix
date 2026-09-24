{
  lib,
  fetchFromGitHub,
  python3Packages,
}:

let
  version = "3.4.7";

  src = fetchFromGitHub {
    owner = "PrefectHQ";
    repo = "fastmcp";
    tag = "v${version}";
    hash = "sha256-EysVbtFbop5ENupc9T5EmtUSZ8osVtQSzpwa6rea/OQ=";
  };

  py-key-value-aio = python3Packages.buildPythonPackage {
    pname = "py-key-value-aio";
    version = "0.4.5";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "strawgate";
      repo = "py-key-value";
      tag = "0.4.5";
      hash = "sha256-N+bqgKkSVGEKW/BEWgcFiHEuFjGbgIn/j33Vd0YoJ7s=";
    };

    postPatch = ''
      substituteInPlace pyproject.toml \
        --replace-fail "uv_build>=0.11.4,<0.12" "uv_build"
    '';

    build-system = [ python3Packages.uv-build ];

    dependencies = with python3Packages; [
      beartype
      typing-extensions
    ];

    optional-dependencies = with python3Packages; {
      filetree = [
        aiofile
        anyio
      ];
      keyring = [ keyring ];
      memory = [ cachetools ];
    };

    pythonImportsCheck = [ "key_value.aio" ];

    meta = {
      description = "Async Key-Value";
      homepage = "https://github.com/strawgate/py-key-value";
      license = lib.licenses.asl20;
    };
  };

  fastmcp-slim = python3Packages.buildPythonPackage {
    pname = "fastmcp-slim";
    inherit version src;
    sourceRoot = "${src.name}/fastmcp_slim";
    pyproject = true;

    build-system = with python3Packages; [
      hatchling
      uv-dynamic-versioning
    ];

    dependencies =
      with python3Packages;
      [
        platformdirs
        pydantic
        pydantic-settings
        python-dotenv
        rich
        typing-extensions
      ]
      ++ python3Packages.pydantic.optional-dependencies.email;

    optional-dependencies = with python3Packages; {
      client = [
        authlib
      ]
      ++ fastmcp-slim.optional-dependencies.mcp
      ++ py-key-value-aio.optional-dependencies.filetree
      ++ py-key-value-aio.optional-dependencies.keyring
      ++ py-key-value-aio.optional-dependencies.memory;
      mcp = [
        exceptiongroup
        httpx
        mcp
        opentelemetry-api
      ];
      server = [
        authlib
        cyclopts
        griffelib
        joserfc
        jsonref
        jsonschema-path
        openapi-pydantic
        packaging
        pyperclip
        python-multipart
        pyyaml
        uncalled-for
        uvicorn
        watchfiles
        websockets
      ]
      ++ [ py-key-value-aio ]
      ++ fastmcp-slim.optional-dependencies.mcp
      ++ py-key-value-aio.optional-dependencies.filetree
      ++ py-key-value-aio.optional-dependencies.keyring
      ++ py-key-value-aio.optional-dependencies.memory;
    };

    pythonImportsCheck = [ "fastmcp" ];

    meta = {
      description = "Dependency-slim FastMCP package";
      homepage = "https://github.com/PrefectHQ/fastmcp";
      license = lib.licenses.asl20;
    };
  };
in
python3Packages.buildPythonPackage {
  pname = "fastmcp";
  inherit version src;
  pyproject = true;

  build-system = with python3Packages; [
    hatchling
    uv-dynamic-versioning
  ];

  dependencies = [
    fastmcp-slim
  ]
  ++ fastmcp-slim.optional-dependencies.client
  ++ fastmcp-slim.optional-dependencies.server;

  pythonImportsCheck = [ "fastmcp" ];

  meta = {
    description = "Fast, Pythonic way to build MCP servers and clients";
    homepage = "https://github.com/PrefectHQ/fastmcp";
    license = lib.licenses.asl20;
  };
}

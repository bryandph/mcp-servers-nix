{ mkServerModule, ... }:
{
  imports = [
    (mkServerModule {
      name = "opentofu";
      packageName = "opentofu-mcp-server";
    })
  ];
}

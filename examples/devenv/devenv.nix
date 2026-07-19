{ inputs, pkgs, ... }:
{
  imports = [ inputs.mcp-servers-nix.devenvModules.default ];

  claude.code.enable = true;

  mcp-servers.programs = {
    filesystem = {
      enable = true;
      args = [ "." ];
    };
    playwright.enable = true;
    context7.enable = true;
  };

  mcp-servers.flavors = {
    claude-code.enable = true;
    codex.enable = true;
    opencode.enable = true;
  };
}

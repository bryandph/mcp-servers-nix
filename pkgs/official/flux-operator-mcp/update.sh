#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix-update
set -euo pipefail

nix-update --flake flux-operator-mcp --use-github-releases

#!/usr/bin/env bash
# Post-install helper: run after plugin/install. Installs hooks, routes, and styles.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "OSR RPG post-install"
echo ""
echo "Prerequisite: plugin/install https://github.com/Mudpuppy12/ares-osr_rpg-plugin"
echo ""
echo "==> Installing Ares hook files..."
"${SCRIPT_DIR}/install_hooks.sh"

echo ""
echo "==> Next steps"
echo "  1. Merge game/config/website.osr_rpg.example.yml into aresmush/game/config/website.yml"
echo "  2. Set demographics.yml gallery groups to match website.yml"
echo "  3. load osr_rpg  (in-game or restart game server)"
echo "  4. cd ares-webportal && bin/deploy  (if hooks/routes/styles changed)"
echo ""
echo "Full guide: ${PLUGIN_ROOT}/INSTALL.md"

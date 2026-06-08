#!/usr/bin/env bash
# Post-install helper: run after plugin/install. Installs hooks, routes, styles, and website nav.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

DEPLOY=0
CHECK_ONLY=0

for arg in "$@"; do
  case "${arg}" in
    --deploy) DEPLOY=1 ;;
    --check) CHECK_ONLY=1 ;;
  esac
done

if [[ "${CHECK_ONLY}" -eq 1 ]]; then
  exec "${SCRIPT_DIR}/check_hooks.sh"
fi

echo "OSR RPG post-install"
echo ""
echo "Prerequisite: plugin/install https://github.com/Mudpuppy12/ares-osr_rpg-plugin"
echo "Portal hook components are copied automatically by plugin/install."
echo "In-game alternative: osr_rpg/install"
echo ""
echo "==> Installing server hooks, routes, styles, and website.yml..."
"${SCRIPT_DIR}/install_hooks.sh"

echo ""
echo "==> Next steps"
echo "  1. Verify demographics.yml groups match website.yml gallery settings (see demographics.osr_rpg.example.yml)"
echo "  2. load osr_rpg  (in-game or restart game server)"
if [[ "${DEPLOY}" -eq 1 ]]; then
  WEBPORTAL_PATH="${WEBPORTAL_PATH:-$(cd "${PLUGIN_ROOT}/../ares-webportal" 2>/dev/null && pwd || true)}"
  if [[ -n "${WEBPORTAL_PATH}" && -x "${WEBPORTAL_PATH}/bin/deploy" ]]; then
    echo "  3. Rebuilding portal..."
    (cd "${WEBPORTAL_PATH}" && bin/deploy)
  else
    echo "  3. cd ares-webportal && bin/deploy  (WEBPORTAL_PATH not set or bin/deploy missing)"
  fi
else
  echo "  3. cd ares-webportal && bin/deploy  (or re-run with --deploy)"
fi
echo "  4. osr_rpg/install_check  (in-game) or ./scripts/install_all.sh --check"
echo ""
echo "Ares hooks guide: https://aresmush.com/tutorials/code/custom-hooks.html"
echo "Full guide: ${PLUGIN_ROOT}/INSTALL.md"

#!/usr/bin/env bash
# Verify OSR RPG hook install (file-based checks).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

ARESMUSH_PATH="${ARESMUSH_PATH:-$(cd "${PLUGIN_ROOT}/../aresmush" 2>/dev/null && pwd || true)}"
WEBPORTAL_PATH="${WEBPORTAL_PATH:-$(cd "${PLUGIN_ROOT}/../ares-webportal" 2>/dev/null && pwd || true)}"

issues=0

check_file() {
  local path="$1"
  if [[ ! -f "${path}" ]]; then
    echo "MISSING: ${path}"
    issues=$((issues + 1))
  fi
}

echo "==> Server hooks"
check_file "${ARESMUSH_PATH}/plugins/chargen/custom_app_review.rb"
check_file "${ARESMUSH_PATH}/plugins/profile/custom_char_fields.rb"
check_file "${ARESMUSH_PATH}/plugins/scenes/custom_char_card.rb"
check_file "${ARESMUSH_PATH}/plugins/website/custom_web_data.rb"

echo "==> Portal hook components"
for name in chargen-custom.hbs profile-custom.hbs live-scene-custom-play.hbs char-card-custom-tabs.hbs sidebar-custom.hbs; do
  check_file "${WEBPORTAL_PATH}/app/components/${name}"
done

echo "==> Routes and styles"
if [[ ! -f "${WEBPORTAL_PATH}/app/custom-routes.js" ]] || ! grep -q 'osr-rpg-shop' "${WEBPORTAL_PATH}/app/custom-routes.js"; then
  echo "MISSING: OSR routes in custom-routes.js"
  issues=$((issues + 1))
fi
if [[ ! -f "${ARESMUSH_PATH}/game/styles/custom_style.scss" ]] || ! grep -q 'osr_rpg_chargen.scss' "${ARESMUSH_PATH}/game/styles/custom_style.scss"; then
  echo "MISSING: osr_rpg_chargen.scss import in custom_style.scss"
  issues=$((issues + 1))
fi

if [[ "${issues}" -eq 0 ]]; then
  echo "OK: OSR RPG hook install check passed."
  exit 0
fi

echo "FAILED: ${issues} issue(s). Run ./scripts/install_all.sh or osr_rpg/install."
exit 1

#!/usr/bin/env bash
# Install OSR RPG Ares custom hook files. Run after plugin/install.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

ARESMUSH_PATH="${ARESMUSH_PATH:-$(cd "${PLUGIN_ROOT}/../aresmush" 2>/dev/null && pwd || true)}"
WEBPORTAL_PATH="${WEBPORTAL_PATH:-$(cd "${PLUGIN_ROOT}/../ares-webportal" 2>/dev/null && pwd || true)}"

if [[ -z "${ARESMUSH_PATH}" || ! -d "${ARESMUSH_PATH}/plugins" ]]; then
  echo "ERROR: Set ARESMUSH_PATH to your aresmush directory." >&2
  exit 1
fi

if [[ -z "${WEBPORTAL_PATH}" || ! -d "${WEBPORTAL_PATH}/app" ]]; then
  echo "ERROR: Set WEBPORTAL_PATH to your ares-webportal directory." >&2
  exit 1
fi

BACKUP_DIR="${PLUGIN_ROOT}/.hook_install_backups/$(date +%Y%m%d%H%M%S)"
mkdir -p "${BACKUP_DIR}"

copy_with_backup() {
  local src="$1"
  local dest="$2"
  if [[ -f "${dest}" ]]; then
    local size
    size="$(wc -c < "${dest}" | tr -d ' ')"
    if [[ "${size}" -gt 200 ]]; then
      mkdir -p "$(dirname "${BACKUP_DIR}/${dest}")"
      cp "${dest}" "${BACKUP_DIR}/${dest}"
      echo "Backed up existing file (${size} bytes): ${dest}"
    fi
  fi
  mkdir -p "$(dirname "${dest}")"
  cp "${src}" "${dest}"
  echo "Installed: ${dest}"
}

PORTAL_HOOK_FILES=(
  chargen-custom-tabs.hbs
  chargen-custom.hbs
  chargen-custom.js
  profile-custom-tabs.hbs
  profile-custom.hbs
  live-scene-custom-play.hbs
  live-scene-custom-play.js
  char-card-custom-tabs.hbs
  char-card-custom-tabs-content.hbs
  sidebar-custom.hbs
)

echo "==> Server hooks (aresmush)"
copy_with_backup \
  "${PLUGIN_ROOT}/game/hooks/chargen/custom_app_review.rb" \
  "${ARESMUSH_PATH}/plugins/chargen/custom_app_review.rb"
copy_with_backup \
  "${PLUGIN_ROOT}/game/hooks/profile/custom_char_fields.rb" \
  "${ARESMUSH_PATH}/plugins/profile/custom_char_fields.rb"
copy_with_backup \
  "${PLUGIN_ROOT}/game/hooks/scenes/custom_char_card.rb" \
  "${ARESMUSH_PATH}/plugins/scenes/custom_char_card.rb"
copy_with_backup \
  "${PLUGIN_ROOT}/game/hooks/website/custom_web_data.rb" \
  "${ARESMUSH_PATH}/plugins/website/custom_web_data.rb"

echo "==> Web portal hook components (fallback; plugin/install copies from webportal/components/)"
PORTAL_SRC="${PLUGIN_ROOT}/webportal/components"
for name in "${PORTAL_HOOK_FILES[@]}"; do
  src="${PORTAL_SRC}/${name}"
  if [[ -f "${src}" ]]; then
    copy_with_backup "${src}" "${WEBPORTAL_PATH}/app/components/${name}"
  fi
done

echo "==> Styles"
STYLES_DEST="${ARESMUSH_PATH}/game/styles/osr_rpg_chargen.scss"
copy_with_backup "${PLUGIN_ROOT}/styles/osr_rpg_chargen.scss" "${STYLES_DEST}"
CUSTOM_STYLE="${ARESMUSH_PATH}/game/styles/custom_style.scss"
if [[ -f "${CUSTOM_STYLE}" ]] && ! grep -q 'osr_rpg_chargen.scss' "${CUSTOM_STYLE}"; then
  {
    echo ''
    echo '@import "osr_rpg_chargen.scss";'
  } >> "${CUSTOM_STYLE}"
  echo "Appended @import to ${CUSTOM_STYLE}"
elif [[ -f "${CUSTOM_STYLE}" ]]; then
  echo "custom_style.scss already imports osr_rpg styles (skipped)."
fi

echo "==> Custom routes"
ROUTES_FILE="${WEBPORTAL_PATH}/app/custom-routes.js"
if [[ ! -f "${ROUTES_FILE}" ]]; then
  echo "WARNING: ${ROUTES_FILE} not found — add osr-rpg routes manually." >&2
else
  if grep -q "osr-rpg-spells" "${ROUTES_FILE}"; then
    echo "custom-routes.js already has OSR routes (skipped)."
  else
    cp "${ROUTES_FILE}" "${BACKUP_DIR}/custom-routes.js"
    python3 - <<'PY' "${ROUTES_FILE}"
import sys
path = sys.argv[1]
with open(path) as f:
    text = f.read()
routes = """
  router.route('osr-rpg-spells', { path: '/osr_rpg/spells' });
  router.route('osr-rpg-spell-detail', { path: '/osr_rpg/spells/:tradition/:level/:name' });
  router.route('osr-rpg-equipment', { path: '/osr_rpg/equipment' });
  router.route('osr-rpg-shop', { path: '/osr_rpg/shop' });
"""
marker = "export default function setupCustomRoutes(router) {"
if marker not in text:
    raise SystemExit("Could not find setupCustomRoutes in custom-routes.js")
text = text.replace(marker, marker + routes, 1)
with open(path, 'w') as f:
    f.write(text)
PY
    echo "Merged OSR routes into ${ROUTES_FILE}"
  fi
fi

echo "==> Website config"
WEBSITE_YML="${ARESMUSH_PATH}/game/config/website.yml"
if [[ ! -f "${WEBSITE_YML}" ]]; then
  echo "WARNING: ${WEBSITE_YML} not found — merge website.osr_rpg.example.yml manually." >&2
else
  ruby "${SCRIPT_DIR}/merge_website_config.rb" "${WEBSITE_YML}" "${PLUGIN_ROOT}/game/config/website.osr_rpg.example.yml"
fi

echo ""
echo "Done. Backups (if any): ${BACKUP_DIR}"
echo "Next: load osr_rpg (or restart game server), then rebuild portal (bin/deploy)."
echo "Or run: osr_rpg/install_check"
echo "Docs: https://aresmush.com/tutorials/code/custom-hooks.html"

# OSR RPG Install Guide

OSR RPG integrates with AresMUSH through [custom hook files](https://aresmush.com/tutorials/code/custom-hooks.html) — **not** by editing core Ares or web portal source. Do **not** add OSR blocks to core templates (`live-scene-control.hbs`, `char-card.hbs`, `chargen-char.hbs`, `profile-system.*`, etc.) or menus and tabs will appear twice.

**Prerequisite:** complete [Step 1 in README.md](README.md#install) (`plugin/install`).

---

## Hook architecture

| Layer | Plugin source | Installed to |
|-------|---------------|--------------|
| Server — app review | `game/hooks/chargen/custom_app_review.rb` | `plugins/chargen/custom_app_review.rb` |
| Server — chargen/profile data | `game/hooks/profile/custom_char_fields.rb` | `plugins/profile/custom_char_fields.rb` |
| Server — scene char card | `game/hooks/scenes/custom_char_card.rb` | `plugins/scenes/custom_char_card.rb` |
| Server — sidebar data | `game/hooks/website/custom_web_data.rb` | `plugins/website/custom_web_data.rb` |
| Portal — chargen Sheet tab | `webportal/components/chargen-custom*` | `app/components/chargen-custom*` (auto via `plugin/install`) |
| Portal — profile Sheet tab | `webportal/components/profile-custom*` | `app/components/profile-custom*` (auto) |
| Portal — live scene Play menu | `webportal/components/live-scene-custom-play.*` | `app/components/live-scene-custom-play.*` (auto) |
| Portal — char card Sheet tab | `webportal/components/char-card-custom-tabs*` | `app/components/char-card-custom-tabs*` (auto) |
| Portal — sidebar quick links | `webportal/components/sidebar-custom.hbs` | `app/components/sidebar-custom.hbs` (auto) |
| Styles | `styles/osr_rpg_chargen.scss` | `game/styles/` + `@import` in `custom_style.scss` |
| Routes | merged into `custom-routes.js` | four `osr-rpg-*` routes |

Plugin components (`OsrRpgChargen`, `OsrRpgProfile`, `LiveSceneOsrRpg`, etc.) and portal hook components are copied automatically by `plugin/install`. Server hooks, routes, styles, and `website.yml` nav entries are installed in Step 2.

---

## Step 2 — Install server hooks, routes, and config

**In-game (recommended):**

```
osr_rpg/install
```

**From shell** (plugin repo or clone):

```bash
ARESMUSH_PATH=/path/to/aresmush WEBPORTAL_PATH=/path/to/ares-webportal ./scripts/install_all.sh
```

Add `--deploy` to rebuild the portal, or `--check` to verify without installing.

`install_all.sh` / `osr_rpg/install` will:

- Copy 4 server hook Ruby files (chargen, profile, scenes, website sidebar)
- Merge OSR routes into `custom-routes.js` (idempotent)
- Install `osr_rpg_chargen.scss` and append `@import` to `custom_style.scss`
- Merge Play/System nav entries into `website.yml` (idempotent)

Re-run after plugin upgrades. Existing hook files over 200 bytes are backed up before overwrite.

---

## Step 3 — Demographics (one-time)

`install_hooks` auto-merges `website.yml` nav entries. Verify gallery group names match your game:

| File | Action |
|------|--------|
| `game/config/demographics.yml` | Align groups with [demographics.osr_rpg.example.yml](game/config/demographics.osr_rpg.example.yml) (Kingdom, Region, Profession) |

On first install, `plugin/install` copies `game/config/*.yml` into your game. On upgrade it skips `game/config/` to preserve local edits.

---

## Step 4 — Load, rebuild, and verify

| Change type | Command |
|-------------|---------|
| Server hooks / plugin code | `load osr_rpg` or restart game server |
| Portal routes / styles | `cd ares-webportal && bin/deploy` |

Verify:

```
osr_rpg/install_check
```

Or: `./scripts/install_all.sh --check`

---

## Install checklist

- [ ] `plugin/install` completed (portal hook components copied automatically)
- [ ] `osr_rpg/install` or `install_all.sh` completed without errors
- [ ] `demographics.yml` groups match `website.yml` gallery settings
- [ ] `load osr_rpg` on game server
- [ ] Portal rebuilt
- [ ] `osr_rpg/install_check` passes
- [ ] Web chargen **Sheet** tab; profile **Sheet** tab; live scene Play menu; Character Card sheet tab
- [ ] Sidebar **OSR RPG** box; System → Spell Lists, Equipment List; Play → Equipment Shop

---

## Multi-plugin games

`custom_char_fields.rb`, `custom_char_card.rb`, and `custom_web_data.rb` are single files per game. If you already use them for another system, merge OSR logic from `game/hooks/` into your existing hooks instead of overwriting blindly (the install script backs up files over 200 bytes).

---

## Upgrading

1. `plugin/install https://github.com/Mudpuppy12/ares-osr_rpg-plugin`
2. `osr_rpg/install` or re-run `install_all.sh`
3. Review [CHANGELOG.md](CHANGELOG.md) for hook or config changes
4. Merge any new YAML from `game/config/` into your game
5. `load osr_rpg` and rebuild portal if routes or styles changed
6. `osr_rpg/install_check`

# OSR RPG Install Guide

OSR RPG integrates with AresMUSH through [custom hook files](https://aresmush.com/tutorials/code/hooks/) — **not** by editing core Ares or web portal source. Do **not** add OSR blocks to core templates (`live-scene-control.hbs`, `char-card.hbs`, `chargen-char.hbs`, `profile-system.*`, etc.) or menus and tabs will appear twice.

**Prerequisite:** complete [Step 1 in README.md](README.md#install) (`plugin/install`).

---

## Hook architecture

| Layer | Plugin source | Installed to |
|-------|---------------|--------------|
| Server — app review | `game/hooks/chargen/custom_app_review.rb` | `plugins/chargen/custom_app_review.rb` |
| Server — chargen/profile data | `game/hooks/profile/custom_char_fields.rb` | `plugins/profile/custom_char_fields.rb` |
| Server — scene char card | `game/hooks/scenes/custom_char_card.rb` | `plugins/scenes/custom_char_card.rb` |
| Portal — chargen Sheet tab | `webportal/hooks/chargen-custom*` | `app/components/chargen-custom*` |
| Portal — profile Sheet tab | `webportal/hooks/profile-custom*` | `app/components/profile-custom*` |
| Portal — live scene Play menu | `webportal/hooks/live-scene-custom-play.*` | `app/components/live-scene-custom-play.*` |
| Portal — char card Sheet tab | `webportal/hooks/char-card-custom-tabs*` | `app/components/char-card-custom-tabs*` |
| Styles | `styles/osr_rpg_chargen.scss` | `game/styles/` + `@import` in `custom_style.scss` |
| Routes | merged into `custom-routes.js` | four `osr-rpg-*` routes |

Plugin components (`OsrRpgChargen`, `OsrRpgProfile`, `LiveSceneOsrRpg`, etc.) are copied automatically by `plugin/install`. Hooks wire them into Ares extension points; sheet data flows through `char.custom.osr_rpg`.

---

## Step 2 — Install hooks

From this plugin repo after `plugin/install`:

```bash
ARESMUSH_PATH=/path/to/aresmush WEBPORTAL_PATH=/path/to/ares-webportal ./scripts/install_hooks.sh
```

Or use the wrapper (after `plugin/install`):

```bash
ARESMUSH_PATH=/path/to/aresmush WEBPORTAL_PATH=/path/to/ares-webportal ./scripts/install_all.sh
```

Re-run after plugin upgrades. The script backs up non-empty existing hook files before overwriting.

---

## Step 3 — Game config (one-time)

These are **setting-specific** YAML edits, not core code patches.

| File | Action |
|------|--------|
| `game/config/website.yml` | Merge [website.osr_rpg.example.yml](game/config/website.osr_rpg.example.yml); set `character_gallery_group` / `character_gallery_subgroup` to match `demographics.yml` |
| `game/config/demographics.yml` | OSE example groups (Kingdom, Region, Profession) — adjust for your game |

On first install, `plugin/install` copies `game/config/*.yml` into your game. On upgrade it skips `game/config/` to preserve local edits — merge any new YAML from this repo by hand.

---

## Step 4 — Load and rebuild

| Change type | Command |
|-------------|---------|
| Server hooks / plugin code | `load osr_rpg` or restart game server |
| Portal hooks / routes / styles | `cd ares-webportal && bin/deploy` |

---

## Install checklist

- [ ] `plugin/install` completed
- [ ] `scripts/install_hooks.sh` (or `install_all.sh`) completed without errors
- [ ] `website.yml` System + Play menus; gallery groups match demographics
- [ ] `load osr_rpg` on game server
- [ ] Portal rebuilt
- [ ] Web chargen **Sheet** tab; profile **Sheet** tab; live scene Play menu; Character Card sheet tab
- [ ] System → Spell Lists, Equipment List; Play → Equipment Shop

---

## Multi-plugin games

`custom_char_fields.rb` and `custom_char_card.rb` are single files per game. If you already use them for another system, merge OSR logic from `game/hooks/` into your existing hooks instead of overwriting blindly (the install script backs up files over 200 bytes).

---

## Upgrading

1. `plugin/install https://github.com/Mudpuppy12/ares-osr_rpg-plugin`
2. Re-run `scripts/install_hooks.sh`
3. Review [CHANGELOG.md](CHANGELOG.md) for hook or config changes
4. Merge any new YAML from `game/config/` into your game
5. `load osr_rpg` and rebuild portal if routes or styles changed

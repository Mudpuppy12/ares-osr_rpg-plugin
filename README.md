# ares-osr_rpg-plugin

OSR RPG character creation for [AresMUSH](https://aresmush.com/) — race-as-class chargen with 24 Advanced Fantasy classes, d6 skill expertise, spell choices, class allowlists, web portal Sheet tab, and in-game `sheet` command.

## Requirements

- AresMUSH 2.x with the web portal installed
- For OSR games, disable FS3 skills/combat (recommended):

```yaml
# game/config/plugins.yml
disabled_plugins:
  - fs3skills
  - fs3combat
```

## Install

**Repo name must be `ares-osr_rpg-plugin`** so the Ares installer derives plugin key `osr_rpg`.

From in-game (admin):

```
plugin/install https://github.com/Mudpuppy12/ares-osr_rpg-plugin
```

Or from the shell on your game server:

```bash
cd aresmush
bundle exec rake add_plugin[https://github.com/Mudpuppy12/ares-osr_rpg-plugin]
```

The installer will:

1. Copy `plugin/` → `aresmush/plugins/osr_rpg/`
2. Copy `game/config/` → `aresmush/game/config/` (first install only)
3. Copy `webportal/` → your web portal `app/` directory
4. Add `osr_rpg` to `plugins.extras` in `plugins.yml`
5. Rebuild the web portal

## Manual steps

These cannot be automated by the plugin importer.

### 1. App review hook

Edit `aresmush/plugins/chargen/custom_app_review.rb` and add at the top of `custom_app_review`:

```ruby
if Manage.is_extra_installed?("osr_rpg")
  return OsrRpg.app_review(char)
end
```

### 2. Reload

```
load osr_rpg
```

Or restart the game server.

### 3. Dice roll sound and styles (web)

`plugin/install` copies `public/sounds/` into your web portal automatically. For manual installs:

```bash
mkdir -p ares-webportal/public/sounds
cp ares-osr_rpg-plugin/public/sounds/osr-rpg-dice.mp3 ares-webportal/public/sounds/
```

Merge `styles/osr_rpg_chargen.scss` from this repo into `aresmush/game/styles/custom_style.scss` (or `@import` it) so chargen dice tray and expertise UI are styled.

### 4. Verify

- Web chargen shows a **Sheet** tab (with `osr_rpg` in extras)
- Save a character with class, alignment, and ability scores
- In-game: `osr_rpg/roll`, `osr_rpg/finish`, and `sheet` work for telnet chargen
- App review includes an **OSR Sheet** section

## What's included

| Component | Description |
|-----------|-------------|
| **24 classes** | 13 human, 10 demihuman, 1 supplemental (Necromancer) |
| **OSR config** | `osr.yml` + split class/spell YAML (deep-merged at boot) |
| **Class allowlist** | `osr_rpg.allowed_classes` in `osr_rpg.yml` (empty = all) |
| **Spell choices** | Arcane L1 spell picker; divine full-list access; Drow auto-Darkness |
| **d6 skill expertise** | L1 allocator for Thief, Acrobat, Assassin, Half-Orc; `osr_rpg/skills` for level-up |
| **Web UI** | `OsrRpgChargen` and `OsrRpgProfile` Ember components |
| **Commands** | `osr_rpg/*` chargen commands, `sheet [name]` |

## Customization

- **`game/config/osr_rpg.yml`** — `osr_rpg_blurb`, `allowed_classes`, `public_sheets`, `hp_per_level`, `require_server_rolls`, shortcuts, permissions
- **`game/config/osr*.yml`** — class progressions, spells, house rules
- Regenerate config (maintainers): `ruby scripts/generate_osr_config.rb`

## Upgrading from ares-rpg-plugin (legacy `rpg`)

If upgrading from the legacy `rpg` plugin:

1. Remove `rpg` from `plugins.extras` and delete `aresmush/plugins/rpg/` if present
2. Install this plugin and run `load osr_rpg`
3. Run game migrations (or restart) so `ose_*` character fields copy to `osr_*`
4. Rebuild the web portal

## Upgrading

Re-running `plugin/install` updates `plugin/` and `webportal/` but **does not overwrite** `game/config/` if the plugin was previously installed (to preserve local edits).

To pick up new OSR YAML on upgrade, manually merge changes from this repo's `game/config/` into your game.

## Repository layout

```
ares-osr_rpg-plugin/
├── plugin/           → aresmush/plugins/osr_rpg/
├── game/config/      → aresmush/game/config/
├── webportal/        → ares-webportal/app/
├── public/sounds/    → ares-webportal/public/sounds/
└── scripts/          → maintainer tools (generate_osr_config.rb)
```

## Development

Source game / reference implementation: the **osr-ares** AresMUSH dev workspace.

Sync from the dev workspace:

```bash
./scripts/sync_osr_rpg_plugin_repo.sh /path/to/ares-osr_rpg-plugin
```

## License

MIT — see [LICENSE](LICENSE).

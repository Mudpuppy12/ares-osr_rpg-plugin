# ares-rpg-plugin

OSE (Old School Essentials) character creation for [AresMUSH](https://aresmush.com/) — race-as-class chargen with 24 Advanced Fantasy classes, d6 thief skills, web portal Sheet tab, and in-game `sheet` command.

## Requirements

- AresMUSH 2.x with the web portal installed
- For OSE games, disable FS3 skills/combat (recommended):

```yaml
# game/config/plugins.yml
disabled_plugins:
  - fs3skills
  - fs3combat
```

## Install

From in-game (admin):

```
plugin/install https://github.com/OSE/ares-rpg-plugin
```

Or from the shell on your game server:

```bash
cd aresmush
bundle exec rake add_plugin[https://github.com/OSE/ares-rpg-plugin]
```

The installer will:

1. Copy `plugin/` → `aresmush/plugins/rpg/`
2. Copy `game/config/` → `aresmush/game/config/` (first install only)
3. Copy `webportal/` → your web portal `app/` directory
4. Add `rpg` to `plugins.extras` in `plugins.yml`
5. Rebuild the web portal

## Manual steps

These cannot be automated by the plugin importer.

### 1. App review hook

Edit `aresmush/plugins/chargen/custom_app_review.rb` and add at the top of `custom_app_review`:

```ruby
if Manage.is_extra_installed?("rpg")
  return Rpg.app_review(char)
end
```

### 2. Reload

```
load rpg
```

Or restart the game server.

### 3. Verify

- Web chargen shows a **Sheet** tab (with `rpg` in extras)
- Save a character with class, alignment, and ability scores
- In-game: `sheet` displays the OSE character sheet
- App review includes an **OSE Sheet** section

## What's included

| Component | Description |
|-----------|-------------|
| **24 classes** | 13 human, 10 demihuman, 1 supplemental (Necromancer) |
| **OSE config** | `ose.yml` + split class/spell YAML (deep-merged at boot) |
| **Web UI** | `RpgChargen` and `RpgProfile` Ember components |
| **Commands** | `sheet [name]` |
| **d6 thief skills** | Thief L1 expertise allocator; base 1-in-6 for skill classes |

## Customization

- **`game/config/rpg.yml`** — `rpg_blurb`, `public_sheets`, shortcuts
- **`game/config/ose*.yml`** — class progressions, spells, house rules
- Regenerate config (maintainers): `ruby scripts/generate_ose_config.rb`

## Upgrading

Re-running `plugin/install` updates `plugin/` and `webportal/` but **does not overwrite** `game/config/` if the plugin was previously installed (to preserve local edits).

To pick up new OSE YAML on upgrade:

1. Compare release notes / diff `game/config/` in this repo
2. Manually merge changes into your game's `aresmush/game/config/ose*.yml`

## Repository layout

```
ares-rpg-plugin/
├── plugin/           → aresmush/plugins/rpg/
├── game/config/      → aresmush/game/config/
├── webportal/        → ares-webportal/app/
└── scripts/          → maintainer tools (generate_ose_config.rb)
```

## Development

Source game / reference implementation: [ose-ares](https://github.com/OSE/ose-ares)

Sync from ose-ares dev workspace:

```bash
./scripts/sync_rpg_plugin_repo.sh /path/to/ares-rpg-plugin
```

## License

MIT — see [LICENSE](LICENSE).

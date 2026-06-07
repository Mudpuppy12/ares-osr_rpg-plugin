# ares-osr_rpg-plugin

OSR RPG for [AresMUSH](https://aresmush.com/) — a hybrid character-and-play system for Old School Renaissance games. Race-as-class chargen, Purist-style character sheets, manual XP/leveling with prime-requisite bonuses, and structured play tools (rolls, HP/AC, spells, scene combat) on **telnet and web**.

Built for **OSE Advanced Fantasy** (24 race-as-class options). Designed to replace FS3 skills/combat on OSR-focused games while keeping narrative adjudication in staff hands.

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
2. Copy `game/config/` → `aresmush/game/config/` (**first install only**)
3. Copy `webportal/components/`, `webportal/routes/`, and `webportal/templates/` → `ares-webportal/app/`
4. Copy `public/sounds/` → `ares-webportal/public/sounds/`
5. Add `osr_rpg` to `plugins.extras` in `plugins.yml`
6. Rebuild the web portal

It does **not** copy styles, `custom-routes.js`, or `website.yml` — see manual steps below.

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

Merge `styles/osr_rpg_chargen.scss` from this repo into `aresmush/game/styles/custom_style.scss` (or `@import` it) so chargen dice tray, expertise UI, and System reference pages are styled.

### 4. Custom routes (System menu pages)

`plugin/install` copies route and template **files**, but Ember still needs route **registration**. If your game uses `ares-webportal/app/custom-routes.js` (recommended), add:

```javascript
router.route('osr-rpg-spells', { path: '/osr_rpg/spells' });
router.route('osr-rpg-spell-detail', { path: '/osr_rpg/spells/:tradition/:level/:name' });
router.route('osr-rpg-equipment', { path: '/osr_rpg/equipment' });
```

Games that edit `router.js` directly can register the same routes there instead.

Add System menu entries to `game/config/website.yml` under `website.top_navbar` → System:

```yaml
- title: Spell Lists
  route: osr-rpg-spells
- title: Equipment List
  route: osr-rpg-equipment
```

### 5. Verify

- Web chargen shows a **Sheet** tab (with `osr_rpg` in extras)
- Save a character with class, alignment, and ability scores
- In-game: `osr_rpg/roll`, `osr_rpg/finish`, and `sheet` work for telnet chargen
- App review includes an **OSR Sheet** section
- Live scene menu shows OSR rolls; `help play` lists play commands
- System → **Spell Lists** shows tradition tabs; spell links open detail pages
- System → **Equipment List** shows armor, weapons, and gear tables

---

## Features

### Character creation (telnet + web)

- **24 Advanced Fantasy classes** — 13 human, 10 demihuman, 1 supplemental (Necromancer)
- **Race-as-class** creation with full L1–14 (or demihuman cap) progression tables
- **Ability scores** — 3d6 in-order or pool-and-assign; optional server-mandatory rolls
- **Alignment** with per-class restrictions enforced at finish
- **d6 thief skills** — L1 expertise allocator for Thief, Acrobat, Assassin, Half-Orc
- **Spell selection** — arcane L1 spell book picker; divine full-list access; Drow restricted L1
- **Class allowlist** — `osr_rpg.allowed_classes` (empty = all classes)
- **Telnet chargen** — `osr_rpg/class`, `alignment`, `roll`, `ability`, `thief`, `spell`, `finish`, `reset`
- **Web chargen** — `OsrRpgChargen` with class browser, dice tray, expertise steppers, spell picker

### Character sheet

- **In-game** — `sheet [name]` (telnet ERB template)
- **Web profile** — Purist-layout `OsrRpgProfile` (abilities, saves, combat, exploration, class skills, spells, special abilities)
- **Live scene** — compact OSR sheet for pose character
- Displays HP, AC, THAC0, saves, spell slots, prepared spells, equipment, exploration skills (LD/OD/SD/FT), racial/class special abilities

### Leveling and XP

- Staff award/remove XP with **prime requisite %** applied on awards (`apply_prime_xp_bonus`)
- Player `osr_rpg/xp` status and `osr_rpg/levelup` (approved characters)
- Level-up grants HP, THAC0, saves, spell slots, thief expertise points
- Arcane casters: `osr_rpg/learn` to add spells to spell book
- Web **Level Up** button on own profile Sheet tab
- Configurable `hp_per_level`: max HD or rolled

### Play rolls (telnet + web live scene)

Shared roll engine (`Rolls.perform_roll`) — same results whether rolled in telnet or posted to the scene log from the web.

| Command | Description |
|---------|-------------|
| `osr_rpg/attack [name/][ac=N]` | d20 attack vs THAC0; hit/miss when AC given |
| `osr_rpg/save <category> [name/]` | Saving throw (death, wands, paralysis, breath, spells) |
| `osr_rpg/skill <key> [name/]` | d6 thief/expertise check |
| `osr_rpg/check <ability> [name/][vs=N]` | d20 ability check |
| `osr_rpg/dice <expr>` | Generic dice (2d6, 1d8, etc.) |
| `osr_rpg/explore <skill>` | Exploration check (listen at door, stuck door, secret door, room trap) |
| `osr_rpg/backstab [ac=N]` | Backstab attack with level-based damage multiplier |
| `osr_rpg/turn [hd=N]` | Turn undead (Cleric/Paladin) |
| `osr_rpg/track [vs=N]` | Ranger tracking check |

### HP, AC, and spells

| Command | Description |
|---------|-------------|
| `osr_rpg/hp <amount>` | Damage (negative) or heal (positive) |
| `osr_rpg/hp/set Name=cur/max` | Staff: set current/max HP |
| `osr_rpg/ac [value]` | Show or set armor class |
| `osr_rpg/prepare <spell>` | Memorize a spell into an open slot |
| `osr_rpg/cast <spell>` | Cast prepared spell (consumes slot) |
| `osr_rpg/rest [name/]` | Clear prepared spells; restore slots |
| `osr_rpg/learn [level/]<spell>` | Arcane: add spell to spell book |

Web profile: quick HP ±1 and **Rest** buttons on your own sheet.

### Scene combat

Server-side combat roster per scene (`OsrRpgSceneCombat`) — shared between telnet and web.

| Command | Description |
|---------|-------------|
| `osr_rpg/combat start` | Staff: begin combat in scene room |
| `osr_rpg/combat join` | Join with initiative roll (d20 + DEX mod) |
| `osr_rpg/combat init Name` | Reroll initiative |
| `osr_rpg/combat damage Name=amount` | Apply damage (syncs PC HP) |
| `osr_rpg/combat heal Name=amount` | Heal combatant |
| `osr_rpg/combat end` | End combat |
| `osr_rpg/combat` | Show initiative-ordered roster |

Web live scene **Combat Tracker** reads/writes the same server state.

### Equipment

Gear catalog in `osr_equipment.yml` (armor, melee weapons, missile weapons, adventuring gear). Web **Equipment List** under System shows the full reference; telnet `equip` uses armor/melee keys from the same file.

| Command | Description |
|---------|-------------|
| `osr_rpg/equip <item>` | Equip leather, chain, shield, sword, etc. |
| `osr_rpg/unequip <item>` | Remove gear |
| `osr_rpg/gear [name]` | List equipped items and AC |

### Staff tools

| Command / permission | Description |
|---------------------|-------------|
| `osr_rpg/xp Name=amount` | Award XP (prime bonus applied) — `manage_osr_rpg_xp` |
| `osr_rpg/xp/remove Name=amount` | Remove XP — `manage_osr_rpg_xp` |
| `osr_rpg/treasure [table]` | Roll GP from treasure tables |
| `osr_rpg/npc <template> [label]` | Show NPC stats or add to scene combat |
| `manage_osr_rpg` | HP set, combat control, rest others, NPC spawn |

NPC templates and monster XP-by-HD tables in `osr_npcs.yml` and `osr_treasure.yml`.

### Web portal components

| Component | Role |
|-----------|------|
| `OsrRpgChargen` | Chargen Sheet tab |
| `OsrRpgProfile` | Profile OSR tab — sheet display, level-up, HP adjust, rest |
| `LiveSceneOsrRpg` | Live scene dropdown — rolls, sheet, server combat tracker |

### System menu reference pages

| Route | API | Purpose |
|-------|-----|---------|
| `osr-rpg-spells` | `osrRpgSpells` | Spell lists by tradition (cleric, druid, magic-user, illusionist, necromancer) |
| `osr-rpg-spell-detail` | `osrRpgSpellDetail` | Spell description and reversal text |
| `osr-rpg-equipment` | `osrRpgEquipment` | Armor, weapons, missile weapons, adventuring gear |

### Config and content

| File | Purpose |
|------|---------|
| `osr_rpg.yml` | House rules, permissions, blurb, shortcuts |
| `osr.yml` | Edition, abilities, alignments, thief d6 rules, turn undead table |
| `osr_classes_*.yml` | 24 classes with XP/THAC0/save/slot progressions |
| `osr_class_details.yml` | Armor, weapons, restrictions, special abilities |
| `osr_spells.yml` | Spell lists by tradition (cleric/druid/MU/illusionist/necromancer) |
| `osr_spell_details.yml` | Spell descriptions for web reference (paraphrased from OSE) |
| `osr_equipment.yml` | Armor, weapons, missile weapons, and adventuring gear catalog |
| `osr_npcs.yml` | NPC combat templates |
| `osr_treasure.yml` | Treasure tables and monster XP by HD |

### Help topics

- `help osr_rpg_chargen` — Chargen commands
- `help leveling` — XP and level-up
- `help play` — Play rolls, HP, spells, combat
- `help sheet` — Sheet command

---

## Customization

- **`game/config/osr_rpg.yml`** — `osr_rpg_blurb`, `allowed_classes`, `public_sheets`, `hp_per_level`, `apply_prime_xp_bonus`, `require_server_rolls`, `default_ac`, shortcuts, permissions
- **`game/config/osr*.yml`** — class progressions, spells, equipment, NPCs, house rules
- Regenerate config (maintainers): `ruby scripts/generate_osr_config.rb`

## Upgrading

Re-running `plugin/install` updates `plugin/` and `webportal/` (components, routes, templates) and rebuilds the portal. It **does not overwrite** `game/config/` on re-install (to preserve local edits).

After upgrading, also:

1. `load osr_rpg` (or restart the game server)
2. Merge new YAML from `game/config/` if needed — especially `osr_spell_details.yml`, `osr_equipment.yml`, and `osr_rpg.yml` blurbs
3. Confirm `custom-routes.js` still has the three `osr-rpg-*` routes (installer does not edit this file)
4. Merge style changes from `styles/osr_rpg_chargen.scss` into `game/styles/custom_style.scss`
5. Add System menu entries to `website.yml` if not already present

## Repository layout

```
ares-osr_rpg-plugin/
├── plugin/           → aresmush/plugins/osr_rpg/
├── game/config/      → aresmush/game/config/
├── webportal/        → ares-webportal/app/
├── public/sounds/    → ares-webportal/public/sounds/
├── styles/           → SCSS for web chargen/sheet UI
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

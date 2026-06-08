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

OSR RPG uses [Ares custom hook files](https://aresmush.com/tutorials/code/custom-hooks.html) — **do not edit core Ares or web portal source** (`live-scene-control`, `chargen-char`, `profile-system`, `char-card`, `chargen/helpers.rb`, etc.). Hooks only; duplicate blocks cause double menus and tabs.

Full details: **[INSTALL.md](INSTALL.md)**.

### Step 1 — Plugin installer

In-game (admin):

```
plugin/install https://github.com/Mudpuppy12/ares-osr_rpg-plugin
```

This copies server code, portal hook components (`chargen-custom*`, `profile-custom*`, etc.), routes/templates, sounds, and game config (first install only), registers the plugin, and restarts the web portal.

### Step 2 — Server hooks, routes, and config

After `plugin/install`:

```
osr_rpg/install
```

This installs server hooks, merges `custom-routes.js` and `website.yml` nav entries, and installs styles. Portal hook components were already copied in Step 1.

### Step 3 — Demographics

Verify [`demographics.yml`](game/config/demographics.osr_rpg.example.yml) groups match your `website.yml` gallery settings. See [INSTALL.md](INSTALL.md).

### Step 4 — Load and verify

```
load osr_rpg
osr_rpg/install_check
```

If routes or styles changed, restart the web portal.

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
- **Chargen equipment shop** — buy from catalog against starting gold (`3d6×10`); cart commits to `osr_inventory` on a **valid full-sheet Save** (class, alignment, abilities, thief/spells, budget)
- **Class change** — changing class in chargen clears cart/inventory, re-rolls starting gold, and resets equipped gear
- **Shop APIs** — `osrRpgEnsureStartingGold` (roll/bootstrap budget), `osrRpgResetShop` (clear shop on class change)

### Character sheet

- **In-game** — `sheet [name]` (telnet ERB template)
- **Web profile** — Purist-layout `OsrRpgProfile` (abilities, saves, combat, exploration, class skills, spells, special abilities)
- **Web equipment management** — **Equipped** / **Carried** lists on profile sheet; **Equip** / **Unequip** on your own character (`osrRpgEquip`); AC updates live
- **Live scene** — compact OSR sheet for pose character
- Displays HP, AC, THAC0, saves, spell slots, prepared spells, gold, inventory, exploration skills (LD/OD/SD/FT), racial/class special abilities

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

### Equipment and inventory

Gear catalog in `osr_equipment.yml` (armor, melee weapons, missile weapons, adventuring gear). **Ascending AC** (higher is better): unarmored 0, leather 2, chain 4, plate 6, shield +1.

| Context | Behavior |
|---------|----------|
| **Chargen (web)** | Equipment & Gear shop after class select; cart → inventory on valid Save; auto-equip best armor/shield/weapon at finalize |
| **Post-chargen shop (web)** | Play → **Equipment Shop** (`/osr_rpg/shop`); buy/sell mundane gear, potions, arcane scrolls; approved characters only |
| **Profile (web)** | Equipped vs Carried sections; equip/unequip buttons on own sheet |
| **Telnet** | `buy`, `sell`, `equip`, `unequip`, `gear` / `inventory` (magic items from `osr_shop.yml` too) |
| **System menu** | Read-only **Equipment List** reference page |

| Command | Description |
|---------|-------------|
| `osr_rpg/buy <item> [=qty]` | Purchase gear from catalog; deducts `osr_gold` |
| `osr_rpg/sell <item> [=qty]` | Sell carried gear at half price |
| `osr_rpg/equip <item>` | Equip owned armor or melee weapon |
| `osr_rpg/unequip <item>` | Unequip gear back into inventory |
| `osr_rpg/gear [name]` | Show gold, equipped gear, inventory, and AC |
| `osr_rpg/inventory [name]` | Alias for `gear` |

Equipped items live in `osr_equipment` and are removed from `osr_inventory` counts (no duplicate display).

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
| `OsrRpgProfile` | Profile Character Sheet tab — sheet display, equipment equip/unequip, level-up, HP adjust, rest |
| `OsrRpgShop` | Post-chargen equipment shop — buy/sell gear, potions, arcane scrolls |
| `LiveSceneOsrRpg` | Live scene dropdown — rolls, sheet, server combat tracker |

### System menu reference pages

| Route | API | Purpose |
|-------|-----|---------|
| `osr-rpg-spells` | `osrRpgSpells` | Spell lists by tradition (cleric, druid, magic-user, illusionist, necromancer) |
| `osr-rpg-spell-detail` | `osrRpgSpellDetail` | Spell description and reversal text |
| `osr-rpg-equipment` | `osrRpgEquipment` | Armor, weapons, missile weapons, adventuring gear |
| `osr-rpg-shop` | `osrRpgShopState` / `Buy` / `Sell` | Post-chargen buy/sell shop (approved characters) |

Chargen, profile, and shop web APIs (not routes — called from components):

| API | Purpose |
|-----|---------|
| `osrRpgEnsureStartingGold` | Roll/bootstrap chargen starting-gold budget |
| `osrRpgResetShop` | Clear cart/inventory and re-roll gold when class changes |
| `osrRpgEquip` | Equip or unequip carried gear; returns refreshed sheet |
| `osrRpgShopState` | Shop catalog, gold, sellable inventory (eligibility gate) |
| `osrRpgShopBuy` | Purchase item; deducts `osr_gold` |
| `osrRpgShopSell` | Sell carried item at half price |

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
| `osr_shop.yml` | Post-chargen magic catalog (potions, arcane scrolls) and shop blurb |
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

Re-run the same install command:

```
plugin/install https://github.com/Mudpuppy12/ares-osr_rpg-plugin
```

That updates plugin server code and copied portal files (components, routes, templates) and restarts the web portal. It **does not overwrite** `game/config/` on re-install, to preserve local edits.

Re-run `osr_rpg/install` after `plugin/install` on upgrade. Review [`CHANGELOG.md`](CHANGELOG.md) and [INSTALL.md](INSTALL.md) for hook or config changes.

Merge any new YAML from this repo's `game/config/` into your game on upgrade (installer skips `game/config/` on re-install) — common files: `osr_spell_details.yml`, `osr_equipment.yml`, `osr_shop.yml`, `osr_rpg.yml`, `osr_spells.yml`.

## Repository layout

```
ares-osr_rpg-plugin/
├── plugin/              → aresmush/plugins/osr_rpg/          (auto)
├── game/config/         → aresmush/game/config/              (auto, first install only)
├── webportal/
│   ├── components/      → OSR components + portal hook files (auto)
│   ├── routes/          → ares-webportal/app/routes/         (auto)
│   └── templates/       → ares-webportal/app/templates/       (auto)
├── game/hooks/          → server hook Ruby sources (osr_rpg/install)
├── plugin/install/      → bundled hook assets for osr_rpg/install
├── public/sounds/       → ares-webportal/public/sounds/      (auto)
├── styles/              → game/styles/ via osr_rpg/install
├── INSTALL.md           → in-game install guide
└── scripts/             → maintainer tools (not required for install)
```

Install details: **[INSTALL.md](INSTALL.md)**.

## Development

Source game / reference implementation: the **osr-ares** AresMUSH dev workspace.

Sync from the dev workspace:

```bash
./scripts/sync_osr_rpg_plugin_repo.sh /path/to/ares-osr_rpg-plugin
```

## License

MIT — see [LICENSE](LICENSE).

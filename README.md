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

### What `plugin/install` does automatically

| Step | Action |
|------|--------|
| Server code | Copies `plugin/` → `aresmush/plugins/osr_rpg/` |
| Game config | Copies `game/config/` → `aresmush/game/config/` (**first install only**) |
| Web components | Copies `webportal/components/` → `ares-webportal/app/components/` |
| Web routes | Copies `webportal/routes/` → `ares-webportal/app/routes/` |
| Web templates | Copies `webportal/templates/` → `ares-webportal/app/templates/` |
| Sounds | Copies `public/sounds/` → `ares-webportal/public/sounds/` |
| Plugin registry | Adds `osr_rpg` to `plugins.extras` in `plugins.yml` |
| Portal build | Rebuilds the web portal |

### What you must do manually

The Ares plugin importer cannot modify these files on your game:

| Item | File(s) | Why |
|------|---------|-----|
| App review hook | `plugins/chargen/custom_app_review.rb` | Core chargen hook — not part of the plugin tree |
| Chargen controller | `ares-webportal/app/controllers/chargen-char.js` | OSR save payload + review/save guardrails — see `webportal/patches/chargen-char.osr_rpg.md` |
| Route registration | `ares-webportal/app/custom-routes.js` (or `router.js`) | Installer copies route **files** but does not register them in Ember |
| Web styles | `aresmush/game/styles/custom_style.scss` | SCSS lives outside the portal `app/` tree |
| System menu | `game/config/website.yml` | Per-game navbar config |
| Reload | In-game `load osr_rpg` | Picks up server-side plugin changes |

### Fresh install checklist

1. Run `plugin/install` (see above).
2. Add the app review hook to `custom_app_review.rb`:

```ruby
if Manage.is_extra_installed?("osr_rpg")
  return OsrRpg.app_review(char)
end
```

3. Patch `ares-webportal/app/controllers/chargen-char.js` per `webportal/patches/chargen-char.osr_rpg.md` (OSR shop data on save/review).

4. Register System reference routes in `ares-webportal/app/custom-routes.js`:

```javascript
router.route('osr-rpg-spells', { path: '/osr_rpg/spells' });
router.route('osr-rpg-spell-detail', { path: '/osr_rpg/spells/:tradition/:level/:name' });
router.route('osr-rpg-equipment', { path: '/osr_rpg/equipment' });
```

Games that edit `router.js` directly can register the same routes there instead.

5. Add System menu entries to `game/config/website.yml` under `website.top_navbar` → System:

```yaml
- title: Spell Lists
  route: osr-rpg-spells
- title: Equipment List
  route: osr-rpg-equipment
```

6. Merge `styles/osr_rpg_chargen.scss` into `aresmush/game/styles/custom_style.scss` (chargen dice tray, profile sheet, spell/equipment reference pages).

7. Run `load osr_rpg` (or restart the game server).

8. Verify:
   - Web chargen shows a **Sheet** tab with **Equipment & Gear** shop (after class selected)
   - Chargen **Budget** shows rolled starting gold (30–180 gp); cart saves on a valid full-sheet **Save**
   - Web profile **Character Sheet** tab shows **Equipment** (Equipped / Carried) with equip buttons on your own sheet
   - `osr_rpg/finish` and `sheet` work on telnet
   - App review includes an **OSR Sheet** section
   - Live scene menu shows OSR rolls
   - System → **Spell Lists** — tradition tabs; spell links open detail pages
   - System → **Equipment List** — armor, weapons, and gear tables

### Manual install (without `plugin/install`)

If you clone the repo by hand:

```bash
cp -r ares-osr_rpg-plugin/plugin aresmush/plugins/osr_rpg
cp -r ares-osr_rpg-plugin/game/config/* aresmush/game/config/
cp -r ares-osr_rpg-plugin/webportal/components ares-webportal/app/
cp -r ares-osr_rpg-plugin/webportal/routes ares-webportal/app/
cp -r ares-osr_rpg-plugin/webportal/templates ares-webportal/app/
mkdir -p ares-webportal/public/sounds
cp ares-osr_rpg-plugin/public/sounds/osr-rpg-dice.mp3 ares-webportal/public/sounds/
```

Then complete steps 2–7 above, add `osr_rpg` to `plugins.extras` in `plugins.yml`, and rebuild the portal.

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
| **Profile (web)** | Equipped vs Carried sections; equip/unequip buttons on own sheet |
| **Telnet** | `buy`, `sell`, `equip`, `unequip`, `gear` / `inventory` |
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
| `LiveSceneOsrRpg` | Live scene dropdown — rolls, sheet, server combat tracker |

### System menu reference pages

| Route | API | Purpose |
|-------|-----|---------|
| `osr-rpg-spells` | `osrRpgSpells` | Spell lists by tradition (cleric, druid, magic-user, illusionist, necromancer) |
| `osr-rpg-spell-detail` | `osrRpgSpellDetail` | Spell description and reversal text |
| `osr-rpg-equipment` | `osrRpgEquipment` | Armor, weapons, missile weapons, adventuring gear |

Chargen and profile web APIs (not routes — called from components):

| API | Purpose |
|-----|---------|
| `osrRpgEnsureStartingGold` | Roll/bootstrap chargen starting-gold budget |
| `osrRpgResetShop` | Clear cart/inventory and re-roll gold when class changes |
| `osrRpgEquip` | Equip or unequip carried gear; returns refreshed sheet |

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

Re-run the same install command:

```
plugin/install https://github.com/Mudpuppy12/ares-osr_rpg-plugin
```

That updates server code and web portal files (components, routes, templates) and rebuilds the portal. It **does not overwrite** `game/config/` on re-install, to preserve local edits.

### Upgrade checklist

1. Run `plugin/install` (above).
2. `load osr_rpg` (or restart the game server).
3. Merge any new YAML from this repo's `game/config/` into your game — common files to check:
   - `osr_spell_details.yml` (spell reference descriptions)
   - `osr_equipment.yml` (expanded gear catalog)
   - `osr_rpg.yml` (`spells_blurb`, `equipment_blurb`, permissions)
   - `osr_spells.yml` (spell list changes)
4. Confirm `custom-routes.js` still registers the three `osr-rpg-*` routes (the installer never edits this file).
5. Merge style changes from `styles/osr_rpg_chargen.scss` into `custom_style.scss` (includes chargen shop, profile equipment rows, spell/equipment reference pages).
6. Confirm `website.yml` still has Spell Lists and Equipment List under System (if not done at first install).
7. Run `load osr_rpg` after server-side plugin updates.
8. Spot-check:
   - Chargen Sheet → Equipment & Gear (budget, cart, save)
   - Profile Character Sheet → Equipment (equip/unequip on own character)
   - System → Spell Lists and Equipment List

## Repository layout

```
ares-osr_rpg-plugin/
├── plugin/              → aresmush/plugins/osr_rpg/          (auto)
├── game/config/         → aresmush/game/config/              (auto, first install only)
├── webportal/
│   ├── components/      → ares-webportal/app/components/     (auto)
│   ├── routes/        → ares-webportal/app/routes/         (auto; register in custom-routes.js)
│   └── templates/     → ares-webportal/app/templates/       (auto)
├── public/sounds/       → ares-webportal/public/sounds/      (auto)
├── styles/              → merge into custom_style.scss       (manual)
└── scripts/             → maintainer tools (not installed)
```

## Development

Source game / reference implementation: the **osr-ares** AresMUSH dev workspace.

Sync from the dev workspace:

```bash
./scripts/sync_osr_rpg_plugin_repo.sh /path/to/ares-osr_rpg-plugin
```

## License

MIT — see [LICENSE](LICENSE).

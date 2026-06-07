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

> **Important:** `plugin/install` copies plugin files only. It does **not** edit core AresMUSH or web portal files. Web chargen, profile sheet, live-scene rolls, reference pages, and the post-chargen shop **will not work** until you complete the [manual core patches](#step-2--manual-core-ares-patches-required) below. Treat those patches as part of the install, not an optional extra.

### Step 1 — Run the plugin installer

From in-game (admin):

```
plugin/install https://github.com/Mudpuppy12/ares-osr_rpg-plugin
```

Or from the shell on your game server:

```bash
cd aresmush
bundle exec rake add_plugin[https://github.com/Mudpuppy12/ares-osr_rpg-plugin]
```

#### What `plugin/install` does automatically

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

#### What `plugin/install` does **not** do

The installer never modifies core game or portal source. You must patch these by hand (see next section):

- Chargen app review hook (Ruby)
- Chargen save/review controller logic (JavaScript)
- Chargen, profile, and live-scene templates (Handlebars)
- Ember route registration (`custom-routes.js`)
- Navbar menu entries (`website.yml`)
- Portal styles (`custom_style.scss`)
- Optional scene-create / play shop links

Patch instructions live in [`webportal/patches/`](webportal/patches/). Copy the described changes into your game's core files.

### Step 2 — Manual core Ares patches (required)

These files live **outside** the plugin tree. Ares does not merge them for you on install or upgrade.

#### Server (aresmush)

| File | Required | What to add | If skipped |
|------|----------|-------------|------------|
| [`aresmush/plugins/chargen/custom_app_review.rb`](https://github.com/aresmush/aresmush/blob/master/install/game.distr/plugins/chargen/custom_app_review.rb) | **Yes** | Hook that calls `OsrRpg.app_review(char)` when `osr_rpg` is installed | Staff app review has no **OSR Sheet** section |

```ruby
# In Chargen.custom_app_review(char):
if Manage.is_extra_installed?("osr_rpg")
  return OsrRpg.app_review(char)
end
```

After editing: `load osr_rpg` (or restart the game server).

#### Web portal — chargen (required for web sheet + shop cart)

| File | Required | What to add | If skipped |
|------|----------|-------------|------------|
| `ares-webportal/app/controllers/chargen-char.js` | **Yes** | OSR payload key, save/review guardrails | Chargen cart/inventory never saves; wrong API field name |
| `ares-webportal/app/templates/chargen-char.hbs` | **Yes** | **Sheet** tab + `<OsrRpgChargen />` when `rpgExtraInstalled` | No web chargen sheet tab |

**Controller patch (full detail):** [`webportal/patches/chargen-char.osr_rpg.md`](webportal/patches/chargen-char.osr_rpg.md)

Summary of controller changes:

1. `osrRpgUpdateCallback` property; `rpgExtraInstalled` checks `osr_rpg` (not `rpg`)
2. `buildQueryDataForChar` sends `osr_rpg:` from the callback (not `rpg:`)
3. **Review:** block on validation `alerts`; reload model before `chargen-review` when OSR installed
4. **Save:** on validation failure, show alert and **do not** `reloadModel` (keeps shop cart in UI)

**Template patch (`chargen-char.hbs`):** add a nav tab and tab pane (same pattern as Traits/FS3):

```hbs
{{#if this.rpgExtraInstalled}}
  <li class="nav-item"><a href="#rpgsheet" data-bs-toggle="tab" class="nav-link">Sheet</a></li>
{{/if}}

{{#if this.rpgExtraInstalled}}
  <div role="tabpanel" class="tab-pane" id="rpgsheet">
    <OsrRpgChargen @model={{this.model}} @updateCallback={{this.osrRpgUpdateCallback}} />
  </div>
{{/if}}
```

#### Web portal — profile sheet (required)

| File | Required | What to add | If skipped |
|------|----------|-------------|------------|
| `ares-webportal/app/components/profile-system.js` | **Yes** | `rpgExtraInstalled` computed checking `osr_rpg` in `game.extra_plugins` | Profile never shows OSR tab |
| `ares-webportal/app/components/profile-system.hbs` | **Yes** | **Sheet** nav tab + `<OsrRpgProfile @char={{this.char}} />` | No web profile sheet, equip, level-up, or HP buttons |

```js
// profile-system.js
rpgExtraInstalled: computed('game.extra_plugins', function () {
  return this.get('game.extra_plugins').some((e) => e == 'osr_rpg');
}),
```

```hbs
{{#if this.rpgExtraInstalled}}
  <li class="nav-item"><a data-bs-toggle="tab" class="nav-link" href="#systemrpg">Sheet</a></li>
{{/if}}

{{#if this.rpgExtraInstalled}}
  <OsrRpgProfile @char={{this.char}} />
{{/if}}
```

#### Web portal — live scene rolls (required)

| File | Required | What to add | If skipped |
|------|----------|-------------|------------|
| `ares-webportal/app/components/live-scene-control.js` | **Yes** | `rpgExtraInstalled` via `isExtraInstalled('osr_rpg')` | Live scene Play menu has no OSR entries |
| `ares-webportal/app/components/live-scene-control.hbs` | **Yes** | `<LiveSceneOsrRpg @scene={{this.scene}} />` in Play dropdown | No web attack/save/skill rolls or combat tracker |

```hbs
{{#if this.rpgExtraInstalled}}
  <LiveSceneOsrRpg @scene={{this.scene}} />
{{/if}}
```

#### Web portal — routes (required for reference pages + shop)

| File | Required | What to add | If skipped |
|------|----------|-------------|------------|
| `ares-webportal/app/custom-routes.js` | **Yes** | Register four `osr-rpg-*` routes | Spell/equipment/shop pages 404 |

The installer copies route **files** under `app/routes/` but does **not** register them in Ember.

```javascript
export default function setupCustomRoutes(router) {
  router.route('osr-rpg-spells', { path: '/osr_rpg/spells' });
  router.route('osr-rpg-spell-detail', { path: '/osr_rpg/spells/:tradition/:level/:name' });
  router.route('osr-rpg-equipment', { path: '/osr_rpg/equipment' });
  router.route('osr-rpg-shop', { path: '/osr_rpg/shop' });
}
```

Games that register routes in `router.js` instead should add the same four entries there.

Rebuild the portal after any `custom-routes.js` change.

#### Game config — navbar (required for menus)

| File | Required | What to add | If skipped |
|------|----------|-------------|------------|
| `aresmush/game/config/website.yml` | **Yes** | System + Play menu entries | No nav links to spell/equipment lists or shop |

Under **System**:

```yaml
- title: Spell Lists
  route: osr-rpg-spells
- title: Equipment List
  route: osr-rpg-equipment
```

Under **Play** (after **Start New Scene**):

```yaml
- title: Equipment Shop
  route: osr-rpg-shop
```

#### Styles (required for usable UI)

| File | Required | What to add | If skipped |
|------|----------|-------------|------------|
| `aresmush/game/styles/custom_style.scss` | **Yes** | Merge contents of `styles/osr_rpg_chargen.scss` from this repo | Chargen dice tray, profile sheet, shop, and reference tables look broken |

#### Optional portal patches (recommended)

| File | Patch doc | What it adds |
|------|-----------|--------------|
| `ares-webportal/app/templates/scene-create.hbs` | [`webportal/patches/scene-create.osr_rpg.md`](webportal/patches/scene-create.osr_rpg.md) | **Equipment Shop** link on Create Scene page |
| `ares-webportal/app/templates/play.hbs` | same doc (optional section) | Shop shortcut in Play sidebar |

### Step 3 — Fresh install checklist

Use this after Step 1 and Step 2:

- [ ] `plugin/install` completed
- [ ] `custom_app_review.rb` calls `OsrRpg.app_review`
- [ ] `chargen-char.js` patched per [`chargen-char.osr_rpg.md`](webportal/patches/chargen-char.osr_rpg.md)
- [ ] `chargen-char.hbs` has Sheet tab + `OsrRpgChargen`
- [ ] `profile-system.js` / `.hbs` have `rpgExtraInstalled` + `OsrRpgProfile`
- [ ] `live-scene-control.js` / `.hbs` have `rpgExtraInstalled` + `LiveSceneOsrRpg`
- [ ] `custom-routes.js` registers all four `osr-rpg-*` routes
- [ ] `website.yml` has System + Play menu entries
- [ ] `custom_style.scss` includes `osr_rpg_chargen.scss` styles
- [ ] (Optional) `scene-create.hbs` and `play.hbs` shop links
- [ ] `load osr_rpg` run on game server
- [ ] Portal rebuilt if routes or styles changed

**Verify:**

- Web chargen **Sheet** tab with **Equipment & Gear** shop (after class selected)
- Chargen **Budget** shows rolled starting gold (30–180 gp); cart saves on valid full-sheet **Save**
- Web profile **Sheet** tab — equipment equip/unequip on your own character
- Play → **Equipment Shop** (approved characters)
- Live scene Play menu — OSR rolls and combat tracker
- System → **Spell Lists** and **Equipment List**
- Telnet `osr_rpg/finish` and `sheet`; app review shows **OSR Sheet**

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

Add `osr_rpg` to `plugins.extras` in `plugins.yml`, complete **all** manual core patches in Step 2, rebuild the portal, and run `load osr_rpg`.

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

That updates plugin server code and copied portal files (components, routes, templates) and rebuilds the portal. It **does not overwrite** `game/config/` on re-install, to preserve local edits.

**Manual core patches are not re-applied on upgrade.** Your edits to `custom_app_review.rb`, `chargen-char.js`, `profile-system.*`, `live-scene-control.*`, `custom-routes.js`, `website.yml`, and `custom_style.scss` persist — but you must **re-check** them when a release adds new routes, menu items, or patch doc changes. Compare your files against [`webportal/patches/`](webportal/patches/) and the [install checklist](#step-3--fresh-install-checklist).

### Upgrade checklist

1. Run `plugin/install` (above).
2. Review [`CHANGELOG.md`](CHANGELOG.md) for new manual steps.
3. Merge any new YAML from this repo's `game/config/` into your game — common files:
   - `osr_spell_details.yml`, `osr_equipment.yml`, `osr_shop.yml`, `osr_rpg.yml`, `osr_spells.yml`
4. Confirm manual patches still in place (installer never touches these):
   - `custom-routes.js` — all four `osr-rpg-*` routes
   - `website.yml` — System spell/equipment entries; Play **Equipment Shop**
   - `custom_style.scss` — merged `osr_rpg_chargen.scss` styles
   - `chargen-char.js` — per patch doc if chargen behavior changed
5. `load osr_rpg` (or restart the game server).
6. Rebuild portal if routes or styles changed.
7. Spot-check chargen sheet, profile sheet, live scene rolls, shop, and System reference pages.

## Repository layout

```
ares-osr_rpg-plugin/
├── plugin/              → aresmush/plugins/osr_rpg/          (auto)
├── game/config/         → aresmush/game/config/              (auto, first install only)
├── webportal/
│   ├── components/      → ares-webportal/app/components/     (auto)
│   ├── routes/          → ares-webportal/app/routes/         (auto; register in custom-routes.js)
│   ├── templates/       → ares-webportal/app/templates/       (auto)
│   └── patches/         → manual edits to CORE portal/game   (you apply by hand)
│       ├── chargen-char.osr_rpg.md
│       └── scene-create.osr_rpg.md
├── public/sounds/       → ares-webportal/public/sounds/      (auto)
├── styles/              → merge into custom_style.scss       (manual)
└── scripts/             → maintainer tools (not installed)
```

**Core files you edit manually (not in this repo):**

| Area | Paths |
|------|-------|
| Server | `aresmush/plugins/chargen/custom_app_review.rb` |
| Chargen | `ares-webportal/app/controllers/chargen-char.js`, `templates/chargen-char.hbs` |
| Profile | `ares-webportal/app/components/profile-system.js`, `profile-system.hbs` |
| Live scene | `ares-webportal/app/components/live-scene-control.js`, `live-scene-control.hbs` |
| Routes | `ares-webportal/app/custom-routes.js` |
| Nav / shop UX | `aresmush/game/config/website.yml`, optional `templates/scene-create.hbs`, `templates/play.hbs` |
| Styles | `aresmush/game/styles/custom_style.scss` |

## Development

Source game / reference implementation: the **osr-ares** AresMUSH dev workspace.

Sync from the dev workspace:

```bash
./scripts/sync_osr_rpg_plugin_repo.sh /path/to/ares-osr_rpg-plugin
```

## License

MIT — see [LICENSE](LICENSE).

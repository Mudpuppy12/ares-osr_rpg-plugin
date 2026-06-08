# Changelog

## Unreleased

Documentation restructure for install clarity.

- **[CORE_ARES_PATCHES.md](CORE_ARES_PATCHES.md)** — single canonical guide for all manual core Ares edits (exact file paths, snippets, checklist, upgrade re-check)
- **README.md** — install section split: automatic `plugin/install` steps vs manual patches (linked to CORE doc)
- **`webportal/patches/*.md`** — thin stubs pointing to CORE_ARES_PATCHES.md sections
- Newly documented required server hooks: `chargen/helpers.rb`, `chargen_char_request_handler.rb`, `chargen_info_request_handler.rb`, `web_data.rb`, `char-card.hbs`

## v3.4.0 — 2026-06-08

Post-chargen web equipment shop with magic items.

- Web **Equipment Shop** (`/osr_rpg/shop`) for approved characters — buy/sell mundane gear, healing potions, L1 arcane scrolls
- Config `osr_shop.yml` — potion and scroll catalog priced at OSE Magical Research baseline (500 gp/spell level)
- Telnet `buy`/`sell` recognize magic inventory keys via extended `EquipmentHelper.lookup_item`
- Web APIs: `osrRpgShopState`, `osrRpgShopBuy`, `osrRpgShopSell`
- Play menu + scene-create link; optional Play sidebar shortcut
- Add **Silver Dagger** (30 gp) to equipment catalog
- Manual patch: `webportal/patches/scene-create.osr_rpg.md`
- Fix profile AC flip on sheet load — ascending armor AC no longer inverted by `migrate_character!`
- Armor AC regression specs for leather, chain, plate, and shield combinations

## v3.3.1 — 2026-06-08

Chargen inventory/armor save fixes and profile equip UI hardening.

- Add **Staff** (2 gp, 1d4, blunt two-handed) and **Club** (3 gp, 1d4, blunt) to equipment catalog

- Fix armor/weapons lost on chargen re-save: merge equipped items into cart payload and `apply_sheet` purchase
- Chargen shop: `initShopCart` restores equipped qty after reload; saved **Carried** row reads persisted inventory
- App review shows **Equipped** and **Carried** separately (armor visible after auto-equip)
- Profile equip: safe equipment/inventory lists, id-based own-profile check, `itemCanEquip` fallback
- Manual web patch: `webportal/patches/chargen-char.osr_rpg.md` (save/review guardrails, `osr_rpg` payload key)
- Specs: re-save armor preservation, `merge_equipped_into_inventory`

## v3.3.0 — 2026-06-08

Chargen shop hardening, web profile equipment, and inventory fixes.

- Web profile **Equipment** section: Equipped / Carried lists with **Equip** / **Unequip** (`osrRpgEquip`)
- Chargen shop UX: save tip, Equipped/Carried display after save, `cart_not_saved` validation alert
- Web APIs: `osrRpgEnsureStartingGold`, `osrRpgResetShop` (class change clears cart and re-rolls gold)
- Fix starting gold showing 0 (unset/zero budget re-roll; handler namespace fix)
- Fix chargen `shopCart` template binding error in Ember
- Fix inventory duplication: equipped items no longer copied into carried inventory on sheet load
- Class change in chargen resets shop server-side and on save when class differs
- Specs for `save_char` inventory commit, equip handler, and migrate cleanup

## v3.2.0 — 2026-06-08

Chargen equipment shop, gold economy, and ascending AC.

- Web chargen **Equipment & Gear** shop with starting-gold budget (`3d6×10`)
- Character fields `osr_gold` (current balance) and `osr_inventory` (owned items)
- Telnet `osr_rpg/buy` and `osr_rpg/sell` commands; expanded `osr_rpg/gear` / `inventory`
- Inventory-aware equip/unequip; auto-equip best armor at chargen finalize
- **Ascending AC** (higher is better): unarmored 0, plate 6, shield +1; THAC0 hit math preserved
- Profile sheet shows current gold and full inventory

## v3.1.1 — 2026-06-08

Spell reference UI polish and install doc updates.

- Fix spell detail lookup for nested `osr_spell_details.yml` config
- URL-safe spell keys for detail links (slashes/apostrophes in spell names)
- Styled spell detail page (tradition badges, effect/reversal panels)
- Tradition accent colors on spell list tabs and level headings
- README: auto vs manual install tables, fresh install and upgrade checklists

## v3.1.0 — 2026-06-08

System menu reference pages.

- Web portal **Spell Lists** and **Equipment List** under System navbar
- API handlers: `osrRpgSpells`, `osrRpgSpellDetail`, `osrRpgEquipment`
- `osr_spell_details.yml` with paraphrased OSE spell descriptions
- Expanded `osr_equipment.yml` (armor, melee/missile weapons, adventuring gear)
- Ember routes/templates in `webportal/`; register in `custom-routes.js`

## v3.0.0 — 2026-06-08

Hybrid OSR play layer.

- Telnet play commands: attack, save, skill, check, dice, explore, backstab, turn, track
- HP/AC management, spell prepare/cast/rest/learn
- Server-side scene combat tracker (web + telnet)
- Equipment catalog, NPC templates, treasure tables
- Web profile HP adjust and rest; live scene AC on attack rolls
- Extended spell lists; Drow darkness fix; tightrope_walking skill key

## v2.0.0 — 2026-06-07

Rename and Chargen V2.

- Plugin renamed `rpg` → `osr_rpg` (display: OSR RPG)
- Config/data renamed `ose_*` → `osr_*` / `osr*.yml`
- Admin class allowlist (`osr_rpg.allowed_classes`)
- Arcane L1 spell picker; divine full-list; Drow auto-Darkness
- d6 skill expertise for Acrobat, Assassin, Half-Orc; `osr_rpg/skills` for level-up pool
- Web components `OsrRpgChargen` / `OsrRpgProfile`

## v1.0.0 — 2026-06-07

Initial release (legacy `ares-rpg-plugin` / `rpg` key).

- OSR race-as-class chargen for 24 Advanced Fantasy classes
- d6 thief skills variant with Thief L1 expertise allocator
- Web portal `RpgChargen` and `RpgProfile` components
- In-game `sheet` command

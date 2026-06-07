# Changelog

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

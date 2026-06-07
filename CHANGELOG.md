# Changelog

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

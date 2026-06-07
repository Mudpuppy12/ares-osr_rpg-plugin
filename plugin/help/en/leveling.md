---
toc: RPG ~ Leveling
summary: OSR XP awards and level-up commands.
---
# osr_rpg/xp and osr_rpg/levelup

## HP per level (admin config)

In `game/config/osr_rpg.yml`, set `hp_per_level` (default `max`):

| Value | HP gained each level |
|-------|----------------------|
| `max` | Maximum hit die + CON modifier (minimum 1) |
| `roll` | Roll hit die + CON modifier (minimum 1) |

This applies at chargen and on every level-up.

## Player commands

```
osr_rpg/xp
osr_rpg/levelup
```

`osr_rpg/xp` shows your current level, XP, and XP needed for the next level.

`osr_rpg/levelup` advances one level when you have enough XP and a finalized OSR sheet. HP, THAC0, saves, and spell slots update from the class progression table.

## Admin commands

Requires `manage_osr_rpg_xp` permission (or admin).

```
osr_rpg/xp <name>=<amount>
osr_rpg/xp/remove <name>=<amount>
osr_rpg/levelup <name>
```

Award or remove XP, or level another character. Admin level-up may bypass the XP requirement.

## Example

```
osr_rpg/xp Bob=2000
osr_rpg/xp Bob
osr_rpg/levelup Bob
sheet Bob
```

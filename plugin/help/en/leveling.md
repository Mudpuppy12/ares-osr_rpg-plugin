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

### Prime requisite XP bonus

When awarding XP (`osr_rpg/xp <name>=<amount>` with a positive amount), enter the **listed** monster or treasure XP. The game applies the character's prime requisite bonus automatically (stored on the sheet at chargen):

| Prime ability score | Bonus |
|---------------------|-------|
| 16+ | +10% |
| 13–15 | +5% |
| 9–12 | 0% |
| 8 or less | −10% |

Example: a fighter with +10% prime requisite awarded `200` base XP receives `220` XP.

XP removal (`osr_rpg/xp/remove`) always deducts the **exact** amount entered — no bonus math.

Set `apply_prime_xp_bonus: false` in `game/config/osr_rpg.yml` to disable automatic adjustment.

## Example

```
osr_rpg/xp Bob=200
osr_rpg/xp Bob
osr_rpg/levelup Bob
sheet Bob
```

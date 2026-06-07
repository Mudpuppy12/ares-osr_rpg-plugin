---
toc: OSR RPG Play Commands
summary: In-game rolls, HP, spells, combat, and class features.
order: 2
---
# OSR RPG Play Commands

Requires a finalized sheet (`osr_rpg/finish`). Most rolls work in telnet and from the web live scene menu.

## Rolls

`osr_rpg/attack [name/][ac=N]` - Attack roll (d20 + THAC0); reports hit/miss when AC given.

`osr_rpg/save <category> [name/]` - Saving throw (death, wands, paralysis, breath, spells).

`osr_rpg/skill <key> [name/]` - Thief/expertise skill check (d6).

`osr_rpg/check <ability> [name/][vs=N]` - Ability check on d20.

`osr_rpg/dice <expr>` - Generic dice (e.g. 2d6, 1d8).

`osr_rpg/explore <skill>` - Exploration check (listen_at_door, open_stuck_door, find_secret_door, find_room_trap).

`osr_rpg/backstab [ac=N]` - Backstab attack (Assassin/Half-Orc).

`osr_rpg/turn [hd=N]` - Turn undead (Cleric/Paladin).

`osr_rpg/track [vs=N]` - Ranger tracking check.

## HP and AC

`osr_rpg/hp <amount>` - Damage (negative) or heal (positive) yourself.

`osr_rpg/hp/set Name=cur/max` - Staff: set HP (requires manage_osr_rpg).

`osr_rpg/ac [value]` - Show or set armor class.

## Spells

`osr_rpg/prepare <spell>` - Memorize a prepared spell.

`osr_rpg/cast <spell>` - Cast a prepared spell (consumes slot).

`osr_rpg/rest [name/]` - Clear prepared spells and restore slots.

`osr_rpg/learn [level/]<spell>` - Arcane: add spell to spell book.

## Combat (scene room)

`osr_rpg/combat start` - Staff: start scene combat.

`osr_rpg/combat join` - Join combat with initiative roll.

`osr_rpg/combat init Name` - Reroll initiative.

`osr_rpg/combat damage Name=amount` - Apply damage.

`osr_rpg/combat heal Name=amount` - Heal combatant.

`osr_rpg/combat end` - End combat.

`osr_rpg/combat` - Show initiative roster.

## Equipment

`osr_rpg/equip <item>` - Equip from catalog (leather, chain, sword, etc.).

`osr_rpg/unequip <item>` - Remove equipment.

`osr_rpg/gear [name]` - List equipped gear and AC.

## Staff tools

`osr_rpg/treasure [table]` - Roll treasure (dungeon_loot, minor_hoard, major_hoard).

`osr_rpg/npc <template> [label]` - Show or add NPC to scene combat (goblin, orc, etc.).

See also: `help osr_rpg_chargen`, `help leveling`, `help sheet`.

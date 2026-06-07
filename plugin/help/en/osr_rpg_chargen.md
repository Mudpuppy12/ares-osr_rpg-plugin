---
toc: OSR RPG ~ Chargen
summary: In-game OSR character creation commands.
---
# osr_rpg

Create your OSR character sheet in-game during chargen. You can also use the web portal Sheet tab; both paths use the same character data.

## Web portal settings

In `game/config/osr_rpg.yml`, `require_server_rolls` (default `true`) forces web chargen to use server-side 3d6 rolls. Set it to `false` to let players opt into client-side rolls via the "Use server rolls" checkbox.

When server rolls are active (required by admins or enabled via the checkbox), web ability scores are read-only and can only be changed by rolling.

The web dice tray and in-game `osr_rpg/roll` output show how many ability roll actions have been used. Staff see this count in app review (`app`).

## Commands

```
osr_rpg/classes [group]
osr_rpg/class <key>
osr_rpg/alignment <Law|Neutrality|Chaos>
osr_rpg/roll [ability]
osr_rpg/ability str=14/dex=12
osr_rpg/thief hide_in_shadows=2/move_silently=1
osr_rpg/spell <spell>
osr_rpg/skills hide_in_shadows=1
osr_rpg/finish
osr_rpg/reset
```

### osr_rpg/classes

Lists available classes. Optional group filter: `human`, `demihuman`, or `supplemental`.

### osr_rpg/class

Sets your class using the class key from `osr_rpg/classes` (e.g. `fighter`, `thief`, `elf`).

Admins may set another character: `osr_rpg/class Bob/fighter`

### osr_rpg/alignment

Sets alignment: Law, Neutrality, or Chaos. Some classes restrict alignment choices.

### osr_rpg/roll

Rolls 3d6 for ability scores. With no argument, rolls all six abilities (STR, DEX, CON, INT, WIS, CHA). With one ability, rolls only that score: `osr_rpg/roll str`

### osr_rpg/ability

Manually set ability scores (3-18). Separate multiple abilities with `/` or spaces: `osr_rpg/ability str=14/dex=12/wis=10`

### osr_rpg/thief

Allocate L1 expertise points for d6 skill classes (Thief, Acrobat, Assassin, Half-Orc). Each point adds +1-in-6 to a skill, up to 5-in-6 total. You must spend exactly the required number of points (usually 4).

Use skill keys from `osr_rpg/classes` (e.g. `hide_in_shadows`, `move_silently`, `climb_walls`).

### osr_rpg/spell

Pick L1 spells for arcane casters, or view spell info for divine/restricted casters. Examples:

```
osr_rpg/spell
osr_rpg/spell Magic Missile
osr_rpg/spell Magic Missile/Sleep
```

### osr_rpg/skills

Spend unspent expertise points after level-up. Example: `osr_rpg/skills hide_in_shadows=1`

### osr_rpg/finish

Validates your sheet and finalizes it — rolling HP, starting gold, THAC0, saves, and thief skill chances. Run `app` to check your application status.

### osr_rpg/reset

Clears your in-progress OSR sheet so you can start over.

## Example Session

```
osr_rpg/classes human
osr_rpg/class fighter
osr_rpg/alignment Law
osr_rpg/roll
osr_rpg/ability wis=12
osr_rpg/finish
app
sheet
```

Thief example:

```
osr_rpg/class thief
osr_rpg/alignment Neutrality
osr_rpg/roll
osr_rpg/thief hide_in_shadows=2 climb_walls=1 move_silently=1
osr_rpg/finish
```

Arcane caster example:

```
osr_rpg/class magic_user
osr_rpg/alignment Neutrality
osr_rpg/roll
osr_rpg/spell Magic Missile
osr_rpg/finish
```

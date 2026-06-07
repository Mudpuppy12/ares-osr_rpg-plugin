#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'

def normalize_key(name)
  name.to_s.strip.downcase.gsub(/\s+/, '_').gsub(/[^a-z0-9_]/, '')
end

def parse_spell_line(line)
  return nil if line.strip.empty?
  return nil unless line =~ /^(.+?)\s*\([^)]*\):\s*(.+)$/

  name = Regexp.last_match(1).strip
  rest = Regexp.last_match(2).strip
  reversal = nil
  if rest =~ /^(.+?)\s*Rev:\s*(.+)$/i
    desc = Regexp.last_match(1).strip
    reversal = Regexp.last_match(2).strip
  else
    desc = rest
  end
  { name: name, description: desc, reversal: reversal }
end

def parse_block(text, level)
  spells = {}
  text.each_line do |line|
    line = line.strip
    next if line.empty?
    next if line =~ /^\d/
    next if line =~ /^OSE|^From |^Complete|^NOTE:|^CRPG|^Necromancer \d|^KEY SPELL|^SPELL LIST|^CLASS|^DOMAINS|^SPELL SLOTS|^Saving|^XP:|^Armor:|^Alignment:|^Race|^\- /
    parsed = parse_spell_line(line)
    next unless parsed

    key = normalize_key(parsed[:name])
    entry = { 'name' => parsed[:name], 'description' => parsed[:description] }
    entry['reversal'] = parsed[:reversal] if parsed[:reversal]
    spells[key] = entry
  end
  spells
end

OB = {
  'cleric' => {
    '1' => <<~TEXT,
      Cure Light Wounds (instant, touch): heals 1d6+1 HP or cures paralysis. Rev: Cause Light Wounds — inflicts 1d6+1, requires melee attack roll.
      Detect Evil (6 turns, 120'): evil-enchanted objects or evil-intentioned creatures glow. Traps/harmful things are not "evil."
      Detect Magic (2 turns, 60'): enchanted objects/areas/creatures glow.
      Light (12 turns, 120'): 15' radius light, or blinds creature (save vs. spells), or cancels darkness. Rev: Darkness.
      Protection from Evil (12 turns, caster): +1 saves vs. other-alignment creatures, −1 to their attacks; enchanted/constructed/summoned creatures cannot melee caster (unless caster engages first).
      Purify Food and Water (permanent, 10'): purifies spoiled/poisonous food/water (6 quarts or 1 ration or food for 12).
      Remove Fear (2 turns, touch): calms fear; magical fear requires save vs. spells +1/caster level. Rev: Cause Fear (flees 2 turns unless save).
      Resist Cold (6 turns, 30'): immunity to non-magical cold; +2 saves vs. cold attacks; −1/die cold damage minimum 1.
      Darkness (12 turns, 120'): 15' radius darkness, or cancels light. Rev: Light.
    TEXT
    '2' => <<~TEXT,
      Bless (6 turns, 60'): allies in 20' square not yet in melee: +1 attack/damage/morale. Rev: Blight (−1 penalty, save vs. spells).
      Find Traps (2 turns, 30'): trapped objects/areas glow blue.
      Hold Person (9 turns, 180'): paralyses 1 target (−2 save) or 1d4 in group. Not undead or >4+1 HD human-like.
      Know Alignment (1 round, 10'): know alignment of one creature/object/location.
      Resist Fire (2 turns, 30'): immunity to non-magical fire; +2 saves vs. fire attacks; −1/die fire damage minimum 1.
      Silence 15' Radius (12 turns, 180'): no sound, no conversation, no spellcasting in 15' area. Can move with creature (save vs. spells).
      Snake Charm (1d4+1 rounds/turns, 60'): renders snakes non-hostile; total HD ≤ caster level.
      Speak with Animals (6 turns, 30'): communicate with one animal type; may ask favors.
    TEXT
    '3' => <<~TEXT,
      Continual Light (permanent, 120'): 30' radius bright light (full daylight), or blinds, or cancels continual darkness. Rev: Continual Darkness.
      Cure Disease (instant, touch): cures any disease; kills green slime. Rev: Cause Disease (death in 2d12 days, −2 attacks, healing halved).
      Growth of Animal (12 turns, 120'): doubles size/strength/carry of one normal animal.
      Locate Object (6 turns, 120'): sense direction of object by general class or specific known object. Cannot locate creatures.
      Remove Curse (instant, touch): removes one curse; may allow discarding cursed item. Rev: Curse (−2 saves/−4 hit/−50% ability score; save vs. spells).
      Striking (1 turn, 30'): one weapon deals +1d6 damage and counts as magical.
    TEXT
    '4' => <<~TEXT,
      Create Water (permanent, touch): 50 gallons (12 humans + 12 mounts for 1 day). +12 humans/mounts per level above 8th.
      Cure Serious Wounds (instant, touch): heals 2d6+2 HP. Rev: Cause Serious Wounds.
      Neutralize Poison (instant, touch): neutralizes poison; can revive poisoned death within 10 rounds.
      Protection from Evil 10' Radius (12 turns, 10' around caster): all allies protected as per Protection from Evil.
      Speak with Plants (3 turns, 30'): communicate with normal or monstrous plants; may ask simple favors.
      Sticks to Snakes (6 turns, 120'): transforms 2d8 sticks into obedient snakes (50% poisonous). AC6[13], HD1, 1d4, MV90'(30').
    TEXT
    '5' => <<~TEXT,
      Commune (3 turns, —): 3 yes/no answers from divine powers (6 questions once/year). Once/week max.
      Create Food (permanent, caster's presence): food for 12 humans + 12 mounts per day. +12 per level above 8th.
      Dispel Evil (concentration up to 1 turn, 30'): ward vs. enchanted/undead, or instantly banish/destroy one (save −2), or dispel cursed item.
      Insect Plague (concentration up to 1 day, 480'): 60' swarm, moves 20'/round. Drives off ≤2 HD creatures. Above ground only.
      Quest (permanent, 30'): commands subject to perform task (save vs. spells); refusal = curse. Rev: Remove Quest (5% fail/level below original caster).
      Raise Dead (instant, touch): restores life to human/demihuman dead ≤4 days/level above 7th; 2 weeks weakness. Rev: Finger of Death (save vs. death or die instantly; chaotic act).
    TEXT
  },
  'druid' => {
    '1' => <<~TEXT,
      Animal Friendship (permanent, 10'): animal saves vs. spells or becomes permanent companion after 6-turn ritual. Up to 2 HD of animals/caster level at once; training: up to 6 tricks, 1 week each.
      Detect Danger (6 turns outdoors/3 turns other, 5'/level): scan areas/creatures/objects to sense immediate vs. potential danger.
      Entangle (1 turn, 80'): 20' radius plants entangle creatures; save vs. spells or cannot move; success = half movement.
      Faerie Fire (as per level duration, 60'): outlines objects/creatures in lambent green. Makes invisible visible; +2 to hit in low light. Harmless.
      Invisibility to Animals (duration varies, touch): subject undetectable to all animal senses (smell, sight, hearing).
      Locate Plant or Animal (6 turns, 120'): sense direction to nearest named species or specific known individual.
      Predict Weather (instant, 1 mi/level): accurate weather knowledge for next 12 hours.
      Speak with Animals (6 turns, 30'): communicate with one animal type; may ask favors.
    TEXT
    '2' => <<~TEXT,
      Barkskin (1 turn/level, touch): +1 AC; +1 to all saves except magical effects.
      Create Water (permanent, touch): 50 gallons.
      Cure Light Wounds (instant, touch): heals 1d6+1 HP or cures paralysis. Rev: Cause Light Wounds.
      Heat Metal (7 rounds, 60'): metal heats over 4 rounds then fades. Round 2: 1d3 damage. Round 3–4: 1d6, flammables ignite. White hot/searing: save vs. spells or limb/body disabled for days.
      Obscuring Mist (4 turns, 10'/level): 10'-high mist blocks normal vision and infravision. Fades in strong winds.
      Produce Flame (2 turns/level, caster): flame in palm; lights flammables; can throw 30' (ends spell).
      Slow Poison (1 hour/level, touch): slows poison to 1 HP/turn; can revive poisoned death within 1 turn/level. Herbal antidote: 10%/level chance.
      Warp Wood (instant, 240'): warps 1 arrow-sized object/level; magic weapons: 10% chance unaffected per plus.
    TEXT
    '3' => <<~TEXT,
      Call Lightning (concentration 1 turn/level, 360'): 1 lightning strike/turn (requires storm clouds); 8d6 damage, 10' radius, save vs. spells for half.
      Growth of Nature (12 turns/permanent, 240'): double animal size/strength OR cause vigorous plant growth (3000 sq ft becomes impassable jungle).
      Hold Animal (concentration, 180'): paralyses up to 1 HD/level of animals; fantastic/intelligent/summoned animals unaffected.
      Protection from Poison (1 turn/level, touch): immunity to venom attacks and poison gases; +4 saves vs. poison breath; neutralizes existing poisons.
      Tree Shape (6 turns+1/level, caster): caster becomes realistic tree; retains normal senses; cancel at will.
      Water Breathing (1 day, 60'): subject breathes water freely. Rev: Air Breathing.
    TEXT
    '4' => <<~TEXT,
      Cure Serious Wounds (instant, touch): heals 2d6+2 HP.
      Dispel Magic (instant, 120'): ends non-instant spell effects in 20' cube. 5% failure per level below original caster.
      Protection from Fire and Lightning (until HP protection used, touch): choose fire or lightning; negates 6 HP/caster level of chosen damage type.
      Speak with Plants (3 turns, 30'): communicate with normal or monstrous plants.
      Summon Animals (concentration, 240'): total HD equal to caster level respond (not insects/magical/intelligent); they understand caster, aid in whatever way possible.
      Temperature Control (1 turn/level, 10' around caster): raise or lower to full natural temperature range.
    TEXT
    '5' => <<~TEXT,
      Commune with Nature (trance 1 turn, half mile/level): reveals 1 fact/level about terrain, water, plants, animals, minerals, or intelligent creatures in a direction. No effect underground.
      Control Weather (concentration, 240 yards): manifests: Calm, Extreme Heat, Fog, High Winds, Rain, Snow, or Tornado (12 HD, 2d8 damage, AC0[19], MV360'(120'), sweeps <2 HD creatures).
      Pass Plant (instant, touch): step into one tree, emerge from same-species tree up to 600 yards away (oak); less for other species.
      Protection from Plants and Animals (1 turn/level, caster): invisible barrier prevents contact by chosen type (plants or animals); caster cannot touch/attack affected life-forms.
      Transmute Rock to Mud (3d6 days, 240'): 3000 sq ft of rock → 10' deep mud; movement −90%. Rev: Transmute Mud to Rock (permanent).
      Wall of Thorns (permanent, 120'): up to 1200 sq ft barrier; entrapment damage = 1d8 + AC score; push through = same per 10'. Immune to normal fire; magical fire destroys in 2 turns.
    TEXT
  },
  'magic_user' => {
    '1' => <<~TEXT,
      Charm Person (varies, 120'): save vs. spells or charmed; treats caster as trusted friend; obeys commands not suicidal/harmful; re-saves at intervals by INT (monthly/weekly/daily for INT 3–8/9–12/13–18).
      Detect Magic (2 turns, 60'): enchanted objects/areas/creatures glow.
      Floating Disc (6 turns, 6'): 3' diameter force disc carries 5000 coins at waist height, follows caster.
      Hold Portal (2d6 turns, 10'): magically holds shut a door/gate/window; Knock opens it; 3+ HD above caster can force in 1 round.
      Light (6 turns+1/level, 120'): 15' radius light, or blinds (save vs. spells), or cancels darkness. Rev: Darkness.
      Magic Missile (1 turn, 150'): 1d6+1 damage, hits unerringly. +2 missiles per 5 levels (3 at 6–10th, 5 at 11–15th).
      Protection from Evil (12 turns, caster): +1 saves vs. other-alignment creatures, −1 to their attacks; summoned/enchanted/constructed cannot melee caster (unless caster engages).
      Read Languages (2 turns, 60'): read any language/code/map.
      Read Magic (1 day, 60'): decipher magical inscriptions/scrolls/spell books/runes. Once read, can re-read without the spell.
      Shield (2 turns, caster): AC 2[17] vs missiles, AC 4[15] vs other attacks.
      Sleep (4d4 turns, 240'): 2d8 HD of ≤4 HD creatures sleep (weakest first) OR 1 creature of 4+1 HD. Undead unaffected. Slapping/wounding wakes. Can be killed instantly with bladed weapon.
      Ventriloquism (2 turns, 60'): voice appears from any location/source within range.
    TEXT
    '2' => <<~TEXT,
      Continual Light (permanent, 120'): 30' radius daylight, or blinds, or cancels darkness. Rev: Continual Darkness (blocks infravision).
      Detect Evil (2 turns, 60'): evil-enchanted objects or evil-intentioned creatures glow.
      Detect Invisible (2 turns, 10'/level): invisible creatures/items revealed.
      ESP (12 turns, 60'): read thoughts; focus 1 turn per direction; multiple creatures = jumble; blocked by lead or 2'+ rock.
      Invisibility (permanent until broken, 60'): invisible until attacks or casts spell. Items dropped become visible.
      Knock (1 round, 60'): opens stuck/barred/locked doors, chests; affects Hold Portal, Wizard Lock; cannot open unknown secret doors.
      Levitate (6 turns, 20'/round, 60'): move vertically at 20'/round; push against solids for lateral movement.
      Locate Object (6 turns, 60'+10'/level): sense direction of general class or specific known object. Cannot locate creatures.
      Mirror Image (6 turns, caster): 1d4 illusory duplicates; each attack destroys one image.
      Phantasmal Force (concentration, 240'): 20' cube visual illusion (monster AC9[10], attack, or scene); ends when caster moves/stops concentrating; pseudo-effects 1d4 turns.
      Web (48 turns, 10'): 10' cube sticky mass; normal humans break free in 2d4 turns; giants in 2 rounds; flammable (1d6 fire damage).
      Wizard Lock (permanent, 60'): magically locks any lockable item; caster passes freely; Knock bypasses; 3+ levels above caster pass freely.
    TEXT
    '3' => <<~TEXT,
      Clairvoyance (12 turns, 60'): see through eyes of creatures in range; focus 1 turn; blocked by lead/2'+ rock.
      Dispel Magic (instant, 120'): ends non-instant spells in 20' cube; 5% failure per level below original caster. Magic items unaffected.
      Fire Ball (instant, 240'): 20' radius sphere; 1d6/level damage; save vs. spells for half.
      Fly (1d6 turns+1/level, touch): flight at 360'(120').
      Haste (3 turns, 240'): 24 creatures in 60' area; double movement and attacks; doesn't double spells or devices.
      Hold Person (1 turn/level, 120'): paralyses 1 (−2 save) or 1d4 in group. Not undead or >4+1 HD.
      Infravision (1 day, touch): see 60' in dark.
      Invisibility 10' Radius (permanent until broken, 240'): all within 10' of target invisible; subjects who move 10'+ away become visible; creatures entering area after casting don't become invisible.
      Lightning Bolt (instant, 180'): 60' long, 5' wide; 1d6/level damage; save vs. spells for half; bounces off solid barriers.
      Protection from Evil 10' Radius (12 turns, 10' around caster): all allies protected as per Protection from Evil.
      Protection from Normal Missiles (12 turns, 30'): one subject immune to small non-magical missiles.
      Water Breathing (1 day, 30'): subject breathes water.
    TEXT
    '4' => <<~TEXT,
      Charm Monster (varies, 120'): charms 3d6 creatures of ≤3 HD OR 1 creature of any HD; save vs. spells; undead unaffected; re-saves by INT.
      Confusion (12 rounds, 120'): 3d6 subjects in 60'; behavior per round: 2–5=attack caster's group, 6–8=no action, 9–12=attack own group; 2+1 HD+ may save each round.
      Dimension Door (instant, 10'): caster or one creature teleports up to 360' to known or offset location; fails if destination solid; unwilling save vs. spells.
      Growth of Plants (permanent, 120'): 3000 sq ft vegetation becomes impassable thorny jungle.
      Massmorph (permanent, 240'): disguise up to 240' diameter force of humanoids as trees/orchard.
      Polymorph Others (permanent, 60'): living subject becomes another creature; new form HD ≤ 2×subject's HD; subject truly becomes new form including behavior; unwilling save vs. spells.
      Polymorph Self (duration varies, caster): caster transforms; retains own HP/saves/attacks; gains physical but not non-physical special abilities; cannot cast spells while polymorphed.
      Remove Curse (instant, touch): removes one curse. Rev: Curse (−2 saves/−4 hit/−50% ability score; save vs. spells).
      Wall of Fire (concentration, 60'): 1200 sq ft immobile violet fire; <4 HD cannot pass; ≥4 HD take 1d6 through; double vs. cold/undead.
      Wall of Ice (permanent, 60'): 1200 sq ft ice wall; <4 HD cannot pass; ≥4 HD take 1d6 to break through; double vs. fire creatures.
      Wizard Eye (6 turns, 240'): invisible magical eye; move up to 120'/turn; caster sees through it (normal+infravision); blocked by solid barriers; passes through 1-inch holes.
    TEXT
    '5' => <<~TEXT,
      Animate Dead (permanent, 60'): animates HD of undead equal to caster level (skeletons: HD as in life; zombies: HD+1).
      Cloudkill (6 turns, 30'): 30' diameter poisonous fog; moves 60'/turn; sinks to lowest level; 1 HP/round; creatures <5 HD save vs. death or die.
      Feeblemind (permanent, 240'): arcane spellcaster saves vs. spells at −4 or becomes feebleminded.
      Hold Monster (1 turn/level, 120'): paralyses 1 (−2 save) or 1d4 in group; undead unaffected.
      Magic Jar (special, 30'): caster's life-force enters receptacle; attempts to possess creatures within 120'; victim saves vs. spells.
      Passwall (3 turns, 30'): 5' diameter hole through 10' of solid rock.
      Telekinesis (concentration up to 6 rounds, 120'): move objects/creatures by thought; 200 coins/level; 20'/round; save vs. spells to resist.
      Teleport (instant, touch): teleport to known location; risk of arriving above/below ground (% by knowledge: exact=5% off-target, moderate=20%, scant=50%).
      Wall of Force (permanent, 60'): invisible force wall immune to most damage; blocks passage and most spells.
      Wall of Stone (permanent, 60'): solid rock wall, 1000 cubic feet, any shape, must rest on solid surface.
    TEXT
    '6' => <<~TEXT,
      Anti-Magic Shell (duration, caster): no spells/effects pass barrier in or out.
      Death Spell (instant, 60'): up to 4d8 HD of creatures in 60' cube save vs. death or die; undead and >7 HD unaffected.
      Disintegrate (instant, 60'): destroys one non-magical creature or object; save vs. death to resist.
      Geas (permanent, 30'): commands quest; save vs. spells; refusal = gradually fatal penalties. Rev: Remove Geas.
      Invisible Stalker (one mission, caster's presence): summons 8 HD invisible stalker; binds to mission; treacherous, twists letter of command; dispel evil banishes it.
      Lower Water (10 turns, 240'): reduces depth of water body by half; up to 10,000 sq ft.
      Move Earth (concentration, 240'): rearranges earth (not stone) at 60'/turn; can excavate downward.
      Part Water (1 turn/level, 60'): 10' wide, 120' long path through water.
      Project Image (6 turns, 240'): illusory duplicate of caster; spells appear to originate from it; image disappears if touched/hit in melee.
      Reincarnation (instant, caster's presence): dead character reincarnated as d10 roll: 1=Cleric, 2=Dwarf, 3=Elf, 4=Fighter, 5=Halfling, 6=MU, 7=Thief, 8=Monster, 9–10=same class; at level 1d6.
    TEXT
  },
  'illusionist' => {
    '1' => <<~TEXT,
      Auditory Illusion (3 turns, 240'): conjure a moving/changing sound; max ~4 humans shouting/caster level.
      Chromatic Orb (instant, 60'): orb hits unerringly; damage and effect by gem/level: Quartz=1d4+Light, Ruby=1d6+Heat, Agate=1d8+Fire, Onyx=1d10+Blindness, Emerald=1d12+Stench, Magnetite=2d6+Magnetism(−2 AC/attacks), Sapphire=2d8+Paralysis.
      Colour Spray (instant, 20' cone 20' wide): 1d6 creatures; ≤caster HD=unconscious 2d4 rounds; up to 2 HD above=blinded 1d4 rounds (save); 3+ HD above=stunned 1 round (save).
      Dancing Lights (1 turn, 40'+10'/level): 1–4 torches/spheres or 1 humanoid light under control.
      Detect Illusion (2 turns, touch): subject sees through illusions within 10'/level; also reveals invisible.
      Glamour (2d6+2/level rounds, caster): change own appearance to another humanoid; height ±1'; can copy a touched individual (attack roll if unwilling); familiar observers save vs. spells.
      Hypnotism (1+1/level rounds, 30'): suggest course of action to 1d6 creatures; harmful suggestions auto-fail; save vs. spells (−2 if "reasonable").
      Light (6+1/level turns, 120'): 15' radius light, or blinds (save vs. spells), or cancels darkness. Rev: Darkness.
      Phantasmal Force (concentration, 240'): visual illusion 20' cube; monster AC9[10], attack, or scene; pseudo-damage effects last 1d4 turns.
      Read Magic (1 day, 60'): decipher magical inscriptions/scrolls/spell books.
      Spook (until broken, 10'): target perceives caster as nightmare monster and flees; save vs. spells each round to break; undead/<animal intelligence unaffected.
      Wall of Fog (4 turns, 30'): 10' cube/level fog bank; blocks normal vision and infravision.
    TEXT
    '2' => <<~TEXT,
      Blindness/Deafness (permanent, 30'): afflicts with illusory blindness or deafness (save vs. spells); removed by dispel magic not cure disease; caster can cancel at will.
      Blur (3 turns, caster): −4 to hit caster (−2 on 2nd+ attempt); +1 saves vs. spells targeting caster directly.
      Detect Magic (2 turns, 60'): enchanted objects/areas/creatures glow.
      False Aura (2 turns, touch): veils aura; deflects detect magic/evil to nearby object; Know Alignment reveals opposite.
      Fascinate (varies, 30'): subject perceives caster as captivating; follows caster; obeys requests (CHA check or spell breaks); animals: 1d4 days, may stay if well-treated.
      Hypnotic Pattern (concentration, 30' square): twisting colours; up to 24 HD hypnotised (stand gazing); harm breaks effect; stays while caster concentrates and remains stationary.
      Improved Phantasmal Force (concentration+2 rounds, 60'): 20' cube illusion with minor sounds; monster AC7[12]; persists 2 rounds after concentration ends.
      Invisibility (permanent until broken, 60'): invisible until attacks or casts spell. Items dropped become visible.
      Magic Mouth (permanent until triggered, touch): up to 25-word message triggered by condition; trigger can only discern visual appearances.
      Mirror Image (6 turns, caster): 1d4 duplicates; each attack destroys one.
      Quasimorph (3d4+2/level rounds, caster): take on appearance of another creature (±50% size); gain limited flight (¼ speed), water breathing, apparent attacks — no special abilities or extra attacks.
      Whispering Wind (special, 1 mile/level): send whispered message to a location; arrives when caster wishes.
    TEXT
    '3' => <<~TEXT,
      Clairaudience (12 turns, 60'): hear through ears of creatures in range; focus 1 turn; blocked by lead or 2'+ rock.
      Daylight (1 turn/level, 120'): 30' radius bright light like full daylight, or blinds, or cancels darkness.
      Dispel Magic (instant, 120'): ends non-instant spells in 20' cube; 5% failure per level below original caster.
      Fear (1 round/level, 60' cone): creatures flee at max speed; 60% drop held items (−5% per level/HD above 1); save vs. spells negates.
      Hallucinatory Terrain (until touched, 240'): conjure or hide terrain; dispelled by intelligent touch.
      Illusory Script (permanent until triggered, touch): written message appears as different text to readers; triggers on condition.
      Invisibility 10' Radius (permanent until broken, 240'): all within 10' of target invisible.
      Paralysis (6 turns, 60'): up to 2 HD/level in 20' cube believe they cannot move; lowest HD first; save vs. spells; mindless unaffected.
      Rope Trick (2 turns/level, touch): rope rises 30'; up to 6 creatures hide in imaginary space at top; invisible/unaffectable inside; duration end = fall from midair.
      Spectral Force (concentration+3 rounds, 60'): 20' cube illusion with sounds/smells/thermal; monster AC5[14]; persists 3 rounds after concentration ends.
      Suggestion (4+4/level turns, 30'): implant suggested action (save vs. spells; −2 if "reasonable"); harmful suggestions auto-fail; undead unaffected.
      Water Breathing (1 day, 30'): subject breathes water.
    TEXT
    '4' => <<~TEXT,
      Confusion (12 rounds, 120'): 3d6 subjects; behavior roll per round: 2–5=attack caster's group, 6–8=no action, 9–12=attack own group.
      Emotion (concentration, 240'): all in 40' square save vs. spells or suffer Fear/Hate(+2 attack/damage/saves/morale)/Hopelessness(surrender or do nothing)/Rage(+1 hit, +3 damage, +5 temp HP, no shield). Emotions counter their opposites.
      Illusionary Wall (permanent, 120'): creates illusory wall up to 1200 sq ft that appears real; intelligent touch may reveal.
      Massmorph (permanent, 240'): disguise up to 240' diameter force of humanoids as trees/orchard.
      Minor Globe of Invulnerability (1 turn/level, caster): 10' radius globe blocks 1st–3rd level spell effects from entering or leaving.
      Phantasmal Killer (1 round/level, 5'/level): subject's worst nightmare pursues it; invulnerable to subject's attacks; THAC0 16[+3]; hit = subject dies of terror (save vs. spells +2); undead/<animal intelligence unaffected.
      Polymorph Others (permanent, 60'): living subject becomes another creature; new form HD ≤ 2×subject's HD; unwilling save vs. spells.
      Rainbow Pattern (concentration, 30' square): 24 HD hypnotised (stand gazing); caster can release pattern to drift away, drawing hypnotised creatures with it; new save if led into danger.
      Shadow Monsters (concentration, 30'): conjure shadow-stuff monsters; 1d2 HP/HD; save vs. spells to see truly (AC9[10], ¼ damage, no specials) vs. perceive as real (full damage, specials work but energy drain/petrify = unconscious/paralysed 1d4 turns).
      Solid Fog (1 turn/level, 30'): 10' cube/level fog; blocks vision and infravision; movement at 1/10 rate; only very strong winds or magical fire clears it.
    TEXT
    '5' => <<~TEXT,
      Advanced Illusion (1 round/level, 240'): 20' cube illusion with sounds/smells/thermal; monster AC5[14]; no concentration needed (responsiveness set at casting).
      Cloudkill (6 turns, 30'): 30' diameter poisonous fog moves 60'/turn; sinks to low ground; 1 hp/round; creatures under 5 HD save vs death each round or die.
      Dream (special, unlimited): send dream message to sleeping subject; may deliver warning or suggestion (save vs spells for harmful content).
      Feeblemind (permanent, 240'): arcane spellcaster saves vs. spells at −4 or becomes feebleminded.
      Major Creation (12 or 6 turns/level, caster): create non-living vegetable or mineral object 1 cubic foot/level; vegetable=12 turns/level, mineral=6 turns/level.
      Mislead (4+1/level rounds, caster): caster becomes invisible while an illusory double appears and acts independently with its own HP equal to caster's current HP.
      Persistent Image (permanent, 240'): 20' cube illusion with sounds/smells/thermal; monster AC5[14]; no concentration needed; scene permanent until dispelled.
      Project Image (6 turns, 240'): illusory duplicate; spells appear to originate from it; disappears if touched or hit in melee.
      Shadow Door (1 turn/level, caster): creates shadowy portal allowing caster to step through to a familiar location within 240'.
      Shadow Magic (concentration, 30'): conjure semi-real shadow monsters; 1d4 HP/HD; save vs spells for half damage and no special effects.
    TEXT
    '6' => <<~TEXT,
      Anti-Magic Shell (duration, caster): no spells/effects pass barrier in or out.
      Mass Suggestion (4+4/level turns, 90'): implant suggested action in up to 1 subject/level; harmful suggestions auto-fail; save vs. spells (−2 if "reasonable"); undead unaffected.
      Permanent Illusion (permanent, 240'): 20' cube illusion with sounds/smells/thermal; monster AC5[14]; no concentration needed; scene permanent until dispelled.
      Programmed Illusion (permanent until triggered, 240'): enchants area to produce illusion when trigger condition occurs; trigger can only discern visual appearances; illusion lasts 1 round/level after triggering.
      Shades (concentration, 30'): shadow monsters with 1d6 HP/HD; save = AC9[10] + ¾ damage; fail = full damage + specials (energy drain/petrify → unconscious/paralysed 1d4 turns).
      True Sight (1 turn/level, 60' of subject): subject sees all as they truly are — secret doors, invisible creatures/objects, illusions, enchantments all revealed.
      Veil (1 turn/level, 240'): alters appearance of group of creatures or objects to look like another type; height ±10%; cannot precisely copy specific individuals.
    TEXT
  },
  'necromancer' => {
    '1' => <<~TEXT,
      Chill Touch (3 rounds +1/level, touch): melee touch vs living target deals 1d4 damage and drains 1 STR; non-rated STR targets take cumulative -1 to attacks instead. Lost STR recovers 1/hour.
      Command Dead (1 round/level, 60'): raises 2d6 humanoid corpses/skeletons with 1 hp each; they obey briefly, attack as 1 HD undead, and cannot use abilities from life.
      Corpse Visage (1 turn/level, caster): caster's face and voice mimic a touched humanoid corpse dead within the last week, including its state of decay.
      Decay (1 turn, corpse touched): reduces corpse/dead body part to bones in 1 turn, making it count as older for raise dead, or touch-attacks fleshy undead for 2d6 damage. Rev: Ward Against Decay (permanently preserves a corpse/body part from decay).
      Deathlight (6 turns +1/level, 60'): wreathes a skull, skeleton, corpse, or undead in flickering light with 15' radius; intelligent undead may save vs spells. Prevents full invisibility on the target.
      Detect Undead (3 turns, 60'): reveals presence and direction of undead, not exact type/location. Blocked by 1' stone, 3' earth, or thin metal.
      Marionette (concentration up to 1 round/level, 30'): controls one corporeal undead up to 4 HD or one person-like living target; save vs paralysis negates. Target can move/attack/freeze, attacks at -2, no special abilities.
      Pass Undead (1 turn/level, caster or touched creature): subject is undetectable to undead. Undead 6+ HD may save to detect; 9+ HD are never fooled.
      Protection From Evil (6 turns, caster): caster gets +1 saves and enemies of another alignment attack at -1. Enchanted/constructed/summoned creatures cannot melee the caster unless the caster engages them in melee.
      Read Magic (1 turn, caster): reads arcane scrolls, other arcane spell books, and magical inscriptions. Once read, the same inscription remains readable later.
      Skull Speech (1 turn/level, 60'): makes one skull speak words chosen by caster; cannot cast through it. Intelligent undead skulls may save vs paralysis.
      Undead Servitor (6 turns +1/level, 30'): reanimates one dead humanoid as obedient skeleton or zombie with no special abilities from life.
    TEXT
    '2' => <<~TEXT,
      Bone Armour (until destroyed, caster): grants AC 5[14]. Melee attackers who hit suffer 1d3 damage from bone shards. Armour absorbs 5 damage +1/level before ending.
      Choke (1 round/level, 90'): living target saves vs spells or ghostly hands choke it for 1d4 damage/round and -2 attacks. Cannot be physically removed; ends if caster is killed or unconscious.
      Death Recall (1 turn, corpse touched): caster witnesses the last 10 minutes of a corpse's life if it died within 24 hours; caster is in a trance and cannot perceive surroundings.
      Detect Magic (2 turns, 60'): permanent and temporary enchantments on objects, areas, or creatures glow.
      Feign Death (6 turns +1/level, caster or touched creature): willing target up to caster level in HD appears dead but keeps hearing/smell. Damage is halved, paralysis/energy drain do not affect target, poison is suspended.
      Paralysing Touch (1 round/level, touch): melee touch forces living target to save vs paralysis or be paralysed 2d4 turns. Elves and creatures larger than ogres are unaffected.
      Seal Tomb (permanent, 60'): seals one crypt door or coffer lid as a magical lock. Caster can pass; knock or a magic-user 3+ levels higher bypasses. Rev: Open Tomb (opens crypt/coffer, dispels seal tomb/wizard lock).
      Skeletal Steed (3 turns/level, 10'): conjures silent skeletal horse for one rider plus up to 3,000 coins; excess load ends spell. Steed crumbles when duration ends.
      Skull Sight (3 turns/level, skull touched): with eyes bound, caster sees through a humanoid skull up to 60' in total darkness with fine detail.
      Silence 15' Radius (12 turns, 180'): creates silent 15' radius; no conversation or spellcasting inside. Can target creature; save vs spells means effect stays stationary, failure makes it move with target.
      Speak With Dead (1 turn, 10'): requires physical remains; asks a dead person's spirit brief truthful questions based on caster level.
      Spectral Hand (2 rounds/level, 60' +10'/level): ghostly hand delivers touch spells up to 4th level at range. It moves 60'/round with concentration, gives +2 on touch attacks.
    TEXT
    '3' => <<~TEXT,
      Animate Dead (1 turn/level, 60'): animates skeletons or zombies from dead creatures up to caster level in total HD; obey caster until duration ends, then crumble.
      Bestow Curse (permanent, 30'): target saves vs spells or suffers caster-defined curse. Maximum effects include -2 saves, -4 to hit, or halving an ability score. Multiple distinct curses may stack.
      Death Ward (1 turn/level, 60'): living subject can keep acting below 0 hp until -10 hp, gains +2 saves vs death/poison. Healing works normally. If spell ends while subject is at 0 hp or lower, subject dies immediately.
      Speak With Dead (1 turn, 10'): requires physical remains; asks a dead person's spirit brief truthful questions based on caster level.
      Spirit Guard (1 day/level or until triggered, 10'): summons invisible dormant spirit to guard location. On trigger, manifests as wraith, warning, or chilling fog.
      Vampiric Touch (1 turn or until used, touch): melee touch vs living target deals 1d6 damage per 2 caster levels, max 6d6; caster heals equal damage, with excess becoming temporary bonus hp for 1 hour.
    TEXT
    '4' => <<~TEXT,
      Contagion (instant, touch): infects living target with disease of caster's choice (blinding, crippling, fevers, etc.); save vs spells negates.
      Death Spell (instant, 240'): up to 4d8 HD of creatures in 60' cube save vs death or die instantly. Undead and creatures above 7 HD unaffected.
      Enervation (instant, 60'): ray drains 1d4 levels from living target; save vs spells for half; nonliving and undead unaffected.
      Fear (instant, 60' cone): creatures in cone save vs spells or flee at maximum speed for 1 round/level. Affected creatures have 60% chance to drop held items.
      Wraithform (2 turns/level, caster): caster becomes semi-incorporeal; passes through cracks; only magic and incorporeal creatures can harm; undead ignore caster (10+ HD save at −4 to notice).
    TEXT
    '5' => <<~TEXT,
      Animate Dead (permanent, 60'): animates skeletons or zombies from dead creatures up to caster level in total HD; obey caster until destroyed or dispelled.
      Cloudkill (6 turns, 30'): 30' diameter poisonous fog moves 60'/turn; sinks to low ground; 1 hp/round; creatures under 5 HD save vs death each round or die.
      Magic Jar (special, caster): caster's body becomes comatose and life-force enters an object within 30'. From jar, caster may possess creatures within 120'; target saves vs spells.
      Raise Dead (instant, touch): resurrects human/demihuman dead within time limit; subject returns with 2-week weakness at 1 hp, half move, no attacks or spells.
      Summon Shadow (permanent until dismissed/slain, 240'): invokes Orcus to send undead servitors; roll 1d6 for type (skeletons, zombies, ghouls, wights, wraiths, or mummies). Concentration needed to command.
    TEXT
    '6' => <<~TEXT,
      Anti-Magic Shell (duration, caster): no spells/effects pass barrier in or out.
      Death Spell (instant, 240'): up to 4d8 HD of creatures in 60' cube save vs death or die instantly. Undead and creatures above 7 HD unaffected.
      Disintegrate (instant, 60'): destroys one non-magical creature or object; save vs death to resist.
      Reincarnation (instant, caster's presence): dead character reincarnated into new body and class per table; returns at level 1d6.
    TEXT
  }
}.freeze

MANUAL = {
  ['necromancer', '4', 'contagion'] => {
    'name' => 'Contagion',
    'description' => 'Infects a living target with a disease of the caster\'s choice (blinding, crippling, fevers, etc.); save vs spells negates.'
  },
  ['necromancer', '4', 'enervation'] => {
    'name' => 'Enervation',
    'description' => 'Black ray drains 1d4 levels from a living target; save vs spells for half; nonliving and undead unaffected.'
  },
  ['necromancer', '5', 'raise_dead'] => {
    'name' => 'Raise Dead',
    'description' => 'Restores life to a human or demihuman dead within the time limit; subject returns with 2 weeks of weakness at 1 hp, half movement, and cannot attack or cast spells.'
  },
  ['necromancer', '5', 'summon_shadow'] => {
    'name' => 'Summon Shadow',
    'description' => 'Invokes Orcus to send undead servitors; roll 1d6 for type (skeletons, zombies, ghouls, wights, wraiths, or mummies). Concentration is needed to command them.'
  }
}.freeze

root = File.expand_path('..', __dir__)
spells_path = File.join(root, 'game/config/osr_spells.yml')
spells_cfg = YAML.safe_load(File.read(spells_path), permitted_classes: [Symbol])
traditions = spells_cfg.dig('osr', 'spells') || {}

details = { 'osr' => { 'spell_details' => {} } }

traditions.each do |tradition, levels|
  details['osr']['spell_details'][tradition] = {}
  levels.each do |level, names|
    parsed = parse_block(OB.dig(tradition, level) || '', level)
    level_details = {}
    names.each do |spell_name|
      key = normalize_key(spell_name)
      manual = MANUAL[[tradition, level, key]]
      if manual
        level_details[key] = manual
      elsif parsed[key]
        level_details[key] = parsed[key].merge('name' => spell_name)
      else
        level_details[key] = {
          'name' => spell_name,
          'description' => "#{spell_name} (#{tradition.titleize.gsub('_', ' ')} level #{level} spell). See OSE Advanced Fantasy Player's Tome for full rules."
        }
      end
    end
    details['osr']['spell_details'][tradition][level] = level_details
  end
end

out_path = File.join(root, 'game/config/osr_spell_details.yml')
header = <<~HEADER
  # OSE Advanced Fantasy Player's Tome v1.1 spell descriptions (paraphrased).
  # Necromancer supplement v0.2 where noted. Used by web portal System → Spell Lists.
  ---
HEADER

File.write(out_path, header + details.to_yaml.sub(/^---\n/, ''))
puts "Wrote #{out_path}"

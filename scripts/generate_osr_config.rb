#!/usr/bin/env ruby
# frozen_string_literal: true
# One-time generator for OSR game config YAML files.
require 'yaml'

CONFIG_DIR = File.expand_path('../game/config', __dir__)

SAVE_TIERS = {
  martial: {
    ranges: [[1, 3], [4, 6], [7, 9], [10, 12], [13, 14]],
    saves: %w[12/13/14/15/16 10/11/12/13/14 8/9/10/10/12 6/7/8/8/10 4/5/6/5/8]
  },
  thief: {
    ranges: [[1, 4], [5, 8], [9, 12], [13, 14]],
    saves: %w[13/14/13/16/15 12/13/11/14/13 10/11/9/12/10 8/9/7/10/8]
  },
  caster: {
    ranges: [[1, 5], [6, 10], [11, 14]],
    saves: %w[13/14/13/16/15 11/12/11/14/12 8/9/8/11/8]
  },
  divine: {
    ranges: [[1, 4], [5, 8], [9, 12], [13, 14]],
    saves: %w[11/12/14/16/15 9/10/12/14/12 6/7/9/11/9 3/5/7/8/7]
  },
  paladin: {
    ranges: [[1, 3], [4, 6], [7, 9], [10, 12], [13, 14]],
    saves: %w[10/11/12/13/14 8/9/10/11/12 6/7/8/8/10 4/5/6/6/8 2/3/4/3/6]
  }
}.freeze

THAC0_TIERS = {
  martial: { ranges: [[1, 3], [4, 6], [7, 9], [10, 12], [13, 14]], values: %w[19 17 14 12 10] },
  thief: { ranges: [[1, 4], [5, 8], [9, 12], [13, 14]], values: %w[19 17 14 12] },
  caster_slow: { ranges: [[1, 5], [6, 10], [11, 14]], values: %w[19 17 14] },
  illusionist: { ranges: [[1, 5], [6, 10], [11, 14]], values: %w[19 17 14] }
}.freeze

def saves_for(level, tier)
  t = SAVE_TIERS[tier]
  t[:ranges].each_with_index do |(lo, hi), i|
    return t[:saves][i] if level >= lo && level <= hi
  end
  t[:saves].last
end

def thac0_for(level, tier)
  t = THAC0_TIERS[tier]
  t[:ranges].each_with_index do |(lo, hi), i|
    return t[:values][i].to_i if level >= lo && level <= hi
  end
  t[:values].last.to_i
end

def parse_saves(s)
  parts = s.split('/').map(&:to_i)
  { death: parts[0], wands: parts[1], paralysis: parts[2], breath: parts[3], spells: parts[4] }
end

def hd_at(level, die, max_level)
  return "#{level}#{die}" if level <= max_level && level <= 9
  bonus = case die
          when 'd8' then (level - 9) * 3
          when 'd6' then (level - 9) * 2
          when 'd4' then level - 9
          else level - 9
          end
  "9#{die}+#{bonus}"
end

def build_progression(xp_table, die, max_level, save_tier, thac0_tier, &spell_slots_proc)
  (1..max_level).map do |lvl|
    row = {
      level: lvl,
      xp: xp_table[lvl - 1],
      hd: lvl <= 9 ? "#{lvl}#{die}" : hd_at(lvl, die, max_level),
      thac0: thac0_for(lvl, thac0_tier),
      saves: parse_saves(saves_for(lvl, save_tier))
    }
    if spell_slots_proc
      slots = spell_slots_proc.call(lvl)
      row[:spell_slots] = slots if slots && !slots.empty?
    end
    row
  end
end

XP = {
  acrobat: [0, 1200, 2400, 4800, 9600, 20_000, 40_000, 80_000, 160_000, 280_000, 400_000, 520_000, 640_000, 760_000],
  assassin: [0, 1500, 3000, 6000, 12_000, 25_000, 50_000, 100_000, 200_000, 300_000, 425_000, 575_000, 750_000, 900_000],
  barbarian: [0, 2500, 5000, 10_000, 18_500, 37_000, 85_000, 140_000, 270_000, 400_000, 530_000, 660_000, 790_000, 920_000],
  bard: [0, 2000, 4000, 8000, 16_000, 32_000, 64_000, 120_000, 240_000, 360_000, 480_000, 600_000, 720_000, 840_000],
  cleric: [0, 1500, 3000, 6000, 12_000, 25_000, 50_000, 100_000, 200_000, 300_000, 400_000, 500_000, 600_000, 700_000],
  druid: [0, 2000, 4000, 7500, 12_500, 20_000, 35_000, 60_000, 90_000, 125_000, 200_000, 300_000, 750_000, 1_500_000],
  fighter: [0, 2000, 4000, 8000, 16_000, 32_000, 64_000, 120_000, 240_000, 360_000, 480_000, 600_000, 720_000, 840_000],
  illusionist: [0, 2500, 5000, 10_000, 20_000, 40_000, 80_000, 150_000, 300_000, 450_000, 600_000, 750_000, 900_000, 1_050_000],
  knight: [0, 2500, 5000, 10_000, 18_500, 37_000, 85_000, 140_000, 270_000, 400_000, 530_000, 660_000, 790_000, 920_000],
  magic_user: [0, 2500, 5000, 10_000, 20_000, 40_000, 80_000, 150_000, 300_000, 450_000, 600_000, 750_000, 900_000, 1_050_000],
  paladin: [0, 2750, 5500, 12_000, 24_000, 45_000, 95_000, 175_000, 350_000, 500_000, 650_000, 800_000, 950_000, 1_100_000],
  ranger: [0, 2250, 4500, 10_000, 20_000, 40_000, 90_000, 150_000, 300_000, 425_000, 550_000, 675_000, 800_000, 925_000],
  thief: [0, 1200, 2400, 4800, 9600, 20_000, 40_000, 80_000, 160_000, 280_000, 400_000, 520_000, 640_000, 760_000],
  necromancer: [0, 2500, 5000, 10_000, 20_000, 40_000, 80_000, 150_000, 300_000, 450_000, 600_000, 750_000, 900_000, 1_050_000]
}.freeze

CLERIC_SLOTS = {
  1 => [], 2 => [1], 3 => [2], 4 => [2, 1], 5 => [2, 2], 6 => [2, 2, 1, 1], 7 => [2, 2, 2, 1, 1],
  8 => [3, 3, 2, 2, 1], 9 => [3, 3, 3, 2, 2], 10 => [4, 4, 3, 3, 2], 11 => [4, 4, 4, 3, 3],
  12 => [5, 5, 4, 4, 3], 13 => [5, 5, 5, 4, 4], 14 => [6, 5, 5, 5, 4]
}.freeze

MU_SLOTS = {
  1 => [1], 2 => [2], 3 => [2, 1], 4 => [2, 2], 5 => [2, 2, 1], 6 => [2, 2, 2],
  7 => [3, 2, 2, 1], 8 => [3, 3, 2, 2], 9 => [3, 3, 3, 2, 1], 10 => [3, 3, 3, 3, 2],
  11 => [4, 3, 3, 3, 2, 1], 12 => [4, 4, 3, 3, 3, 2], 13 => [4, 4, 4, 3, 3, 3], 14 => [4, 4, 4, 4, 3, 3]
}.freeze

def slot_hash(level, table, max_levels: 6)
  arr = table[level] || []
  h = {}
  arr.each_with_index { |n, i| h[(i + 1).to_s] = n if n && n > 0 }
  h
end

def write_yaml(path, data)
  File.write(path, data.to_yaml)
  puts "Wrote #{path}"
end

# --- Core config ---
osr_core = {
  'osr' => {
    'edition' => 'advanced_fantasy',
    'creation_method' => 'race_as_class',
    'class_groups' => %w[human demihuman supplemental],
    'abilities' => %w[str dex con int wis cha],
    'alignments' => ['Law', 'Neutrality', 'Chaos'],
    'starting_gold' => '3d6x10',
    'ability_modifiers' => {
      '3' => -3, '4' => -2, '5' => -2, '6' => -1, '7' => -1, '8' => -1,
      '9' => 0, '10' => 0, '11' => 0, '12' => 0,
      '13' => 1, '14' => 1, '15' => 1,
      '16' => 2, '17' => 2, '18' => 3
    },
    'prime_req_xp_bonus' => { 'low' => -10, 'mid' => 0, 'high' => 5, 'prime' => 10 },
    'thief_skills_d6' => {
      'base_chance' => 1,
      'max_chance' => 5,
      'expertise_per_level' => { '1' => 4, 'default' => 2 },
      'skills' => %w[climb_sheer find_remove_traps hear_noise hide_in_shadows move_silently open_locks pick_pockets read_languages],
      'pick_pockets_penalty_per_3_levels' => 1
    },
    'save_tiers' => SAVE_TIERS.transform_values { |v| v[:saves] }
  }
}

write_yaml(File.join(CONFIG_DIR, 'osr.yml'), osr_core)

# --- Human classes ---
humans = {}

humans['fighter'] = {
  'group' => 'human', 'race' => 'human', 'name' => 'Fighter', 'hd' => 'd8', 'max_level' => 14,
  'prime_reqs' => ['str'], 'spell_tradition' => nil,
  'blurb' => 'Master of weapons and warfare.',
  'progression' => build_progression(XP[:fighter], 'd8', 14, :martial, :martial)
}

humans['cleric'] = {
  'group' => 'human', 'race' => 'human', 'name' => 'Cleric', 'hd' => 'd6', 'max_level' => 14,
  'prime_reqs' => ['wis'], 'spell_tradition' => 'cleric', 'spells_from_level' => 2,
  'blurb' => 'Divine champion; clerical spells from 2nd level.',
  'progression' => build_progression(XP[:cleric], 'd6', 14, :divine, :martial) { |l| slot_hash(l, CLERIC_SLOTS, max_levels: 5) if l >= 2 }
}

humans['magic_user'] = {
  'group' => 'human', 'race' => 'human', 'name' => 'Magic-User', 'hd' => 'd4', 'max_level' => 14,
  'prime_reqs' => ['int'], 'spell_tradition' => 'magic_user', 'spells_from_level' => 1,
  'armor' => 'none',
  'blurb' => 'Arcane spellcaster; no armor.',
  'progression' => build_progression(XP[:magic_user], 'd4', 14, :caster, :caster_slow) { |l| slot_hash(l, MU_SLOTS) }
}

humans['thief'] = {
  'group' => 'human', 'race' => 'human', 'name' => 'Thief', 'hd' => 'd4', 'max_level' => 14,
  'prime_reqs' => ['dex'], 'spell_tradition' => nil,
  'skill_system' => 'd6', 'skill_set' => 'all_eight', 'l1_expertise_points' => 4,
  'blurb' => 'Skulduggerer; allocate 4 d6 expertise points at 1st level.',
  'progression' => build_progression(XP[:thief], 'd4', 14, :thief, :thief)
}

%w[acrobat assassin].each do |c|
  humans[c] = {
    'group' => 'human', 'race' => 'human', 'name' => c.capitalize, 'hd' => 'd4', 'max_level' => 14,
    'prime_reqs' => ['dex'], 'spell_tradition' => nil,
    'skill_system' => 'd6',
    'skill_set' => c == 'acrobat' ? %w[climb_sheer hide_in_shadows move_silently tightrope_walking] : %w[hide_in_shadows move_silently],
    'alignment_restrictions' => c == 'assassin' ? ['Neutrality', 'Chaos'] : nil,
    'blurb' => c == 'assassin' ? 'Deadly infiltrator; cannot be Lawful.' : 'Agile performer and climber.',
    'progression' => build_progression(XP[c.to_sym], 'd4', 14, :thief, :thief)
  }.compact
end

humans['barbarian'] = {
  'group' => 'human', 'race' => 'human', 'name' => 'Barbarian', 'hd' => 'd8', 'max_level' => 14,
  'prime_reqs' => %w[con str], 'min_scores' => { 'dex' => 9 }, 'spell_tradition' => nil,
  'blurb' => 'Wilderness warrior.',
  'progression' => build_progression(XP[:barbarian], 'd8', 14, :martial, :martial)
}

humans['knight'] = {
  'group' => 'human', 'race' => 'human', 'name' => 'Knight', 'hd' => 'd8', 'max_level' => 14,
  'prime_reqs' => ['str'], 'min_scores' => { 'con' => 9, 'dex' => 9 }, 'no_missiles' => true,
  'blurb' => 'Chivalric warrior; no missile weapons.',
  'progression' => build_progression(XP[:knight], 'd8', 14, :martial, :martial)
}

humans['bard'] = {
  'group' => 'human', 'race' => 'human', 'name' => 'Bard', 'hd' => 'd6', 'max_level' => 14,
  'prime_reqs' => ['cha'], 'min_scores' => { 'dex' => 9, 'int' => 9 },
  'spell_tradition' => 'druid', 'spells_from_level' => 2, 'max_spell_level' => 4,
  'blurb' => 'Lore and performance; druid spells from 2nd.',
  'progression' => build_progression(XP[:bard], 'd6', 14, :thief, :thief) do |l|
    next nil if l < 2
    slots = { 2 => { '1' => 1 }, 3 => { '1' => 2 }, 4 => { '1' => 3 }, 5 => { '1' => 3, '2' => 1 },
              6 => { '1' => 3, '2' => 2 }, 7 => { '1' => 3, '2' => 3 }, 8 => { '1' => 3, '2' => 3, '3' => 1 },
              9 => { '1' => 3, '2' => 3, '3' => 2 }, 10 => { '1' => 3, '2' => 3, '3' => 3 },
              11 => { '1' => 3, '2' => 3, '3' => 3, '4' => 1 }, 12 => { '1' => 3, '2' => 3, '3' => 3, '4' => 2 },
              13 => { '1' => 3, '2' => 3, '3' => 3, '4' => 3 }, 14 => { '1' => 4, '2' => 4, '3' => 3, '4' => 3 } }
    slots[l]
  end
}

humans['druid'] = {
  'group' => 'human', 'race' => 'human', 'name' => 'Druid', 'hd' => 'd6', 'max_level' => 14,
  'prime_reqs' => ['wis'], 'spell_tradition' => 'druid', 'spells_from_level' => 1,
  'alignment_restrictions' => ['Neutrality'],
  'blurb' => 'Nature priest; Neutral alignment only.',
  'progression' => build_progression(XP[:druid], 'd6', 14, :divine, :martial) do |l|
    druid = { 1 => { '1' => 1 }, 2 => { '1' => 2 }, 3 => { '1' => 2, '2' => 1 }, 4 => { '1' => 2, '2' => 2 },
              5 => { '1' => 2, '2' => 2, '3' => 1, '4' => 1 }, 6 => { '1' => 2, '2' => 2, '3' => 2, '4' => 1, '5' => 1 },
              7 => { '1' => 3, '2' => 3, '3' => 2, '4' => 2, '5' => 1 }, 8 => { '1' => 3, '2' => 3, '3' => 3, '4' => 2, '5' => 2 },
              9 => { '1' => 4, '2' => 4, '3' => 3, '4' => 3, '5' => 2 }, 10 => { '1' => 4, '2' => 4, '3' => 4, '4' => 3, '5' => 3 },
              11 => { '1' => 5, '2' => 5, '3' => 4, '4' => 4, '5' => 3 }, 12 => { '1' => 5, '2' => 5, '3' => 5, '4' => 4, '5' => 4 },
              13 => { '1' => 6, '2' => 5, '3' => 5, '4' => 5, '5' => 4 }, 14 => { '1' => 6, '2' => 6, '3' => 5, '4' => 5, '5' => 5 } }
    druid[l]
  end
}

humans['illusionist'] = {
  'group' => 'human', 'race' => 'human', 'name' => 'Illusionist', 'hd' => 'd4', 'max_level' => 14,
  'prime_reqs' => ['int'], 'min_scores' => { 'dex' => 9 }, 'spell_tradition' => 'illusionist',
  'armor' => 'none', 'blurb' => 'Arcane illusionist; no armor.',
  'progression' => build_progression(XP[:illusionist], 'd4', 14, :caster, :illusionist) { |l| slot_hash(l, MU_SLOTS) }
}

humans['paladin'] = {
  'group' => 'human', 'race' => 'human', 'name' => 'Paladin', 'hd' => 'd8', 'max_level' => 14,
  'prime_reqs' => %w[str wis], 'min_scores' => { 'cha' => 9 }, 'spell_tradition' => 'cleric',
  'spells_from_level' => 9, 'alignment_restrictions' => ['Law'], 'turn_undead_from_level' => 3,
  'blurb' => 'Holy warrior; Lawful; clerical spells from 9th.',
  'progression' => build_progression(XP[:paladin], 'd8', 14, :paladin, :martial) do |l|
    next nil if l < 9
    p = { 9 => { '1' => 1 }, 10 => { '1' => 2 }, 11 => { '1' => 2, '2' => 1 }, 12 => { '1' => 2, '2' => 2 },
          13 => { '1' => 2, '2' => 2, '3' => 1 }, 14 => { '1' => 3, '2' => 2, '3' => 1 } }
    p[l]
  end
}

humans['ranger'] = {
  'group' => 'human', 'race' => 'human', 'name' => 'Ranger', 'hd' => 'd8', 'max_level' => 14,
  'prime_reqs' => ['str'], 'min_scores' => { 'con' => 9, 'wis' => 9 },
  'spell_tradition' => 'druid', 'spells_from_level' => 8,
  'alignment_restrictions' => ['Law', 'Neutrality'], 'tracking_base' => 20,
  'blurb' => 'Woodland guardian; druid spells from 8th.',
  'progression' => build_progression(XP[:ranger], 'd8', 14, :martial, :martial) do |l|
    next nil if l < 8
    r = { 8 => { '1' => 1 }, 9 => { '1' => 2 }, 10 => { '1' => 2, '2' => 1 }, 11 => { '1' => 2, '2' => 2 },
          12 => { '1' => 2, '2' => 2, '3' => 1 }, 13 => { '1' => 3, '2' => 2, '3' => 1 }, 14 => { '1' => 3, '2' => 2, '3' => 2 } }
    r[l]
  end
}

write_yaml(File.join(CONFIG_DIR, 'osr_classes_human.yml'), { 'osr' => { 'classes' => humans } })

# Demihuman progressions - embedded from Advanced tables
def demi_row(level, xp, hd, thac0, saves, slots = nil)
  row = { 'level' => level, 'xp' => xp, 'hd' => hd, 'thac0' => thac0,
          'saves' => parse_saves(saves) }
  row['spell_slots'] = slots if slots
  row
end

demihumans = {}

demihumans['dwarf'] = {
  'group' => 'demihuman', 'race' => 'dwarf', 'name' => 'Dwarf', 'hd' => 'd8', 'max_level' => 12,
  'prime_reqs' => ['str'], 'min_scores' => { 'con' => 9 }, 'blurb' => 'Stout underground warrior.',
  'progression' => [
    demi_row(1, 0, '1d8', 19, '8/9/10/13/12'), demi_row(2, 2200, '2d8', 19, '8/9/10/13/12'),
    demi_row(3, 4400, '3d8', 19, '8/9/10/13/12'), demi_row(4, 8800, '4d8', 17, '6/7/8/10/10'),
    demi_row(5, 17_000, '5d8', 17, '6/7/8/10/10'), demi_row(6, 35_000, '6d8', 17, '6/7/8/10/10'),
    demi_row(7, 70_000, '7d8', 14, '4/5/6/7/8'), demi_row(8, 140_000, '8d8', 14, '4/5/6/7/8'),
    demi_row(9, 270_000, '9d8', 14, '4/5/6/7/8'), demi_row(10, 400_000, '9d8+3', 12, '2/3/4/4/6'),
    demi_row(11, 530_000, '9d8+6', 12, '2/3/4/4/6'), demi_row(12, 660_000, '9d8+9', 12, '2/3/4/4/6')
  ]
}

demihumans['half_orc'] = {
  'group' => 'demihuman', 'race' => 'half_orc', 'name' => 'Half-Orc', 'hd' => 'd6', 'max_level' => 8,
  'prime_reqs' => %w[dex str], 'skill_system' => 'd6',
  'skill_set' => %w[hide_in_shadows move_silently pick_pockets], 'back_stab' => true,
  'blurb' => 'Strong and stealthy; d6 thief skills at 1-in-6.',
  'progression' => [
    demi_row(1, 0, '1d6', 19, '13/14/13/16/15'), demi_row(2, 1800, '2d6', 19, '13/14/13/16/15'),
    demi_row(3, 3600, '3d6', 19, '13/14/13/16/15'), demi_row(4, 7000, '4d6', 19, '13/14/13/16/15'),
    demi_row(5, 14_000, '5d6', 17, '12/13/11/14/13'), demi_row(6, 28_000, '6d6', 17, '12/13/11/14/13'),
    demi_row(7, 60_000, '7d6', 17, '12/13/11/14/13'), demi_row(8, 120_000, '8d6', 17, '12/13/11/14/13')
  ]
}

demihumans['halfling'] = {
  'group' => 'demihuman', 'race' => 'halfling', 'name' => 'Halfling', 'hd' => 'd6', 'max_level' => 8,
  'prime_reqs' => %w[dex str], 'min_scores' => { 'con' => 9, 'dex' => 9 },
  'alignment_restrictions' => ['Law', 'Neutrality'],
  'blurb' => 'Small and brave; Lawful or Neutral only.',
  'progression' => [
    demi_row(1, 0, '1d6', 19, '8/9/10/13/12'), demi_row(2, 2000, '2d6', 19, '8/9/10/13/12'),
    demi_row(3, 4000, '3d6', 19, '8/9/10/13/12'), demi_row(4, 8000, '4d6', 17, '6/7/8/10/10'),
    demi_row(5, 16_000, '5d6', 17, '6/7/8/10/10'), demi_row(6, 32_000, '6d6', 17, '6/7/8/10/10'),
    demi_row(7, 64_000, '7d6', 14, '4/5/6/7/8'), demi_row(8, 120_000, '8d6', 14, '4/5/6/7/8')
  ]
}

# Elf, Gnome, Half-Elf, Drow, Duergar, Svirfneblin, Wood Elf - abbreviated with key levels from Open Brain
elf_prog = [
  [1, 0, '1d6', 19, '12/13/13/15/15', { '1' => 1 }], [2, 4000, '2d6', 19, '12/13/13/15/15', { '1' => 2 }],
  [3, 8000, '3d6', 19, '12/13/13/15/15', { '1' => 2, '2' => 1 }], [4, 16_000, '4d6', 17, '10/11/11/13/12', { '1' => 2, '2' => 2 }],
  [5, 32_000, '5d6', 17, '10/11/11/13/12', { '1' => 2, '2' => 2, '3' => 1 }],
  [6, 64_000, '6d6', 17, '10/11/11/13/12', { '1' => 2, '2' => 2, '3' => 2 }],
  [7, 120_000, '7d6', 14, '8/9/9/10/10', { '1' => 3, '2' => 2, '3' => 2, '4' => 1 }],
  [8, 250_000, '8d6', 14, '8/9/9/10/10', { '1' => 3, '2' => 3, '3' => 2, '4' => 2 }],
  [9, 400_000, '9d6', 14, '8/9/9/10/10', { '1' => 3, '2' => 3, '3' => 3, '4' => 2, '5' => 1 }],
  [10, 600_000, '9d6+2', 12, '6/7/8/8/8', { '1' => 3, '2' => 3, '3' => 3, '4' => 3, '5' => 2 }]
]
demihumans['elf'] = {
  'group' => 'demihuman', 'race' => 'elf', 'name' => 'Elf', 'hd' => 'd6', 'max_level' => 10,
  'prime_reqs' => %w[int str], 'min_scores' => { 'int' => 9 }, 'spell_tradition' => 'magic_user',
  'spells_from_level' => 1, 'blurb' => 'Graceful arcane race-class.',
  'progression' => elf_prog.map { |a| demi_row(*a) }
}

gnome_prog = [
  [1, 0, '1d4', 19, '8/9/10/14/11', { '1' => 1 }], [2, 3000, '2d4', 19, '8/9/10/14/11', { '1' => 2 }],
  [3, 6000, '3d4', 19, '8/9/10/14/11', { '1' => 2, '2' => 1 }], [4, 12_000, '4d4', 19, '8/9/10/14/11', { '1' => 2, '2' => 2 }],
  [5, 30_000, '5d4', 19, '8/9/10/14/11', { '1' => 2, '2' => 2, '3' => 1 }],
  [6, 60_000, '6d4', 17, '6/7/8/11/9', { '1' => 2, '2' => 2, '3' => 2 }],
  [7, 120_000, '7d4', 17, '6/7/8/11/9', { '1' => 3, '2' => 2, '3' => 2, '4' => 1 }],
  [8, 240_000, '8d4', 17, '6/7/8/11/9', { '1' => 3, '2' => 3, '3' => 2, '4' => 2 }]
]
demihumans['gnome'] = {
  'group' => 'demihuman', 'race' => 'gnome', 'name' => 'Gnome', 'hd' => 'd4', 'max_level' => 8,
  'prime_reqs' => %w[dex int], 'min_scores' => { 'con' => 9 }, 'spell_tradition' => 'illusionist',
  'blurb' => 'Small illusionist race-class.',
  'progression' => gnome_prog.map { |a| demi_row(*a) }
}

demihumans['drow'] = {
  'group' => 'demihuman', 'race' => 'drow', 'name' => 'Drow', 'hd' => 'd6', 'max_level' => 10,
  'prime_reqs' => %w[str wis], 'min_scores' => { 'int' => 9 }, 'spell_tradition' => 'cleric',
  'l1_spells' => ['darkness'], 'spells_from_level' => 2,
  'blurb' => 'Underdark elf; darkness only at 1st level.',
  'progression' => [
    demi_row(1, 0, '1d6', 19, '12/13/13/15/12', { '1' => 1 }),
    demi_row(2, 4000, '2d6', 19, '12/13/13/15/12', { '1' => 2 }),
    demi_row(3, 8000, '3d6', 19, '12/13/13/15/12', { '1' => 2, '2' => 1 }),
    demi_row(4, 16_000, '4d6', 17, '10/11/11/13/10', { '1' => 2, '2' => 2 }),
    demi_row(5, 32_000, '5d6', 17, '10/11/11/13/10', { '1' => 2, '2' => 2, '3' => 1 }),
    demi_row(6, 64_000, '6d6', 17, '10/11/11/13/10', { '1' => 2, '2' => 2, '3' => 2, '4' => 1 }),
    demi_row(7, 120_000, '7d6', 14, '8/9/9/10/8', { '1' => 3, '2' => 2, '3' => 2, '4' => 2, '5' => 1 }),
    demi_row(8, 250_000, '8d6', 14, '8/9/9/10/8', { '1' => 3, '2' => 3, '3' => 2, '4' => 2, '5' => 2 }),
    demi_row(9, 400_000, '9d6', 14, '8/9/9/10/8', { '1' => 4, '2' => 3, '3' => 3, '4' => 3, '5' => 2 }),
    demi_row(10, 600_000, '9d6+2', 12, '6/7/8/8/8', { '1' => 4, '2' => 4, '3' => 4, '4' => 3, '5' => 3 })
  ]
}

demihumans['duergar'] = {
  'group' => 'demihuman', 'race' => 'duergar', 'name' => 'Duergar', 'hd' => 'd6', 'max_level' => 10,
  'prime_reqs' => ['str'], 'min_scores' => { 'con' => 9, 'int' => 9 }, 'blurb' => 'Gray dwarf with mental powers.',
  'progression' => [
    demi_row(1, 0, '1d6', 19, '8/9/10/13/12'), demi_row(2, 2800, '2d6', 19, '8/9/10/13/12'),
    demi_row(3, 5600, '3d6', 19, '8/9/10/13/12'), demi_row(4, 11_200, '4d6', 17, '6/7/8/10/10'),
    demi_row(5, 23_000, '5d6', 17, '6/7/8/10/10'), demi_row(6, 46_000, '6d6', 17, '6/7/8/10/10'),
    demi_row(7, 100_000, '7d6', 14, '4/5/6/7/8'), demi_row(8, 200_000, '8d6', 14, '4/5/6/7/8'),
    demi_row(9, 300_000, '9d6', 14, '4/5/6/7/8'), demi_row(10, 400_000, '9d6+3', 12, '2/3/4/4/6')
  ]
}

demihumans['half_elf'] = {
  'group' => 'demihuman', 'race' => 'half_elf', 'name' => 'Half-Elf', 'hd' => 'd6', 'max_level' => 12,
  'prime_reqs' => %w[int str], 'min_scores' => { 'cha' => 9, 'con' => 9 },
  'spell_tradition' => 'magic_user', 'spells_from_level' => 2, 'blurb' => 'Mixed heritage arcane caster.',
  'progression' => [
    demi_row(1, 0, '1d6', 19, '12/13/13/15/15', nil), demi_row(2, 2500, '2d6', 19, '12/13/13/15/15', { '1' => 1 }),
    demi_row(3, 5000, '3d6', 19, '12/13/13/15/15', { '1' => 2 }), demi_row(4, 10_000, '4d6', 17, '10/11/11/13/12', { '1' => 2 }),
    demi_row(5, 20_000, '5d6', 17, '10/11/11/13/12', { '1' => 2, '2' => 1 }),
    demi_row(6, 40_000, '6d6', 17, '10/11/11/13/12', { '1' => 2, '2' => 2 }),
    demi_row(7, 80_000, '7d6', 14, '8/9/9/10/10', { '1' => 2, '2' => 2 }),
    demi_row(8, 150_000, '8d6', 14, '8/9/9/10/10', { '1' => 2, '2' => 2, '3' => 1 }),
    demi_row(9, 300_000, '9d6', 14, '8/9/9/10/10', { '1' => 3, '2' => 2, '3' => 1 }),
    demi_row(10, 450_000, '9d6+2', 12, '6/7/8/8/8', { '1' => 3, '2' => 2, '3' => 2 }),
    demi_row(11, 600_000, '9d6+4', 12, '6/7/8/8/8', { '1' => 3, '2' => 2, '3' => 2, '4' => 1 }),
    demi_row(12, 750_000, '9d6+6', 12, '6/7/8/8/8', { '1' => 3, '2' => 3, '3' => 2, '4' => 1 })
  ]
}

demihumans['svirfneblin'] = {
  'group' => 'demihuman', 'race' => 'svirfneblin', 'name' => 'Svirfneblin', 'hd' => 'd6', 'max_level' => 8,
  'prime_reqs' => ['str'], 'min_scores' => { 'con' => 9 }, 'blurb' => 'Deep gnome; stone blend.',
  'progression' => [
    demi_row(1, 0, '1d6', 19, '8/9/10/14/11'), demi_row(2, 2400, '2d6', 19, '8/9/10/14/11'),
    demi_row(3, 4800, '3d6', 19, '8/9/10/14/11'), demi_row(4, 10_000, '4d6', 17, '6/7/8/11/9'),
    demi_row(5, 20_000, '5d6', 17, '6/7/8/11/9'), demi_row(6, 40_000, '6d6', 17, '6/7/8/11/9'),
    demi_row(7, 80_000, '7d6', 14, '4/5/6/9/7'), demi_row(8, 160_000, '8d6', 14, '4/5/6/9/7')
  ]
}

demihumans['wood_elf'] = {
  'group' => 'demihuman', 'race' => 'wood_elf', 'name' => 'Wood Elf', 'hd' => 'd6', 'max_level' => 10,
  'prime_reqs' => %w[dex wis], 'min_scores' => { 'dex' => 9, 'wis' => 9 },
  'spell_tradition' => 'druid', 'supplemental' => true,
  'blurb' => 'Forest guardian; druid spells (supplement).',
  'progression' => [
    demi_row(1, 0, '1d6', 19, '12/13/13/15/15', { '1' => 1 }), demi_row(2, 3000, '2d6', 19, '12/13/13/15/15', { '1' => 2 }),
    demi_row(3, 6000, '3d6', 19, '12/13/13/15/15', { '1' => 2, '2' => 1 }),
    demi_row(4, 12_000, '4d6', 17, '10/11/11/13/12', { '1' => 2, '2' => 2 }),
    demi_row(5, 24_000, '5d6', 17, '10/11/11/13/12', { '1' => 2, '2' => 2, '3' => 1 }),
    demi_row(6, 48_000, '6d6', 17, '10/11/11/13/12', { '1' => 2, '2' => 2, '3' => 2 }),
    demi_row(7, 100_000, '7d6', 14, '8/9/9/10/10', { '1' => 3, '2' => 2, '3' => 2, '4' => 1 }),
    demi_row(8, 200_000, '8d6', 14, '8/9/9/10/10', { '1' => 3, '2' => 3, '3' => 2, '4' => 2 }),
    demi_row(9, 350_000, '9d6', 14, '8/9/9/10/10', { '1' => 3, '2' => 3, '3' => 3, '4' => 2, '5' => 1 }),
    demi_row(10, 500_000, '9d6+2', 12, '6/7/8/8/8', { '1' => 3, '2' => 3, '3' => 3, '4' => 3, '5' => 2 })
  ]
}

write_yaml(File.join(CONFIG_DIR, 'osr_classes_demihuman.yml'), { 'osr' => { 'classes' => demihumans } })

write_yaml(File.join(CONFIG_DIR, 'osr_classes_supplemental.yml'), {
  'osr' => {
    'classes' => {
      'necromancer' => {
        'group' => 'supplemental', 'race' => 'human', 'name' => 'Necromancer', 'hd' => 'd4', 'max_level' => 14,
        'prime_reqs' => ['int'], 'min_scores' => { 'wis' => 9 }, 'spell_tradition' => 'necromancer',
        'armor' => 'none', 'playtest' => true,
        'blurb' => 'Necromantic arcanist (v0.2 playtest); WIS 9 min.',
        'progression' => build_progression(XP[:necromancer], 'd4', 14, :caster, :caster_slow) { |l| slot_hash(l, MU_SLOTS) }
      }
    }
  }
})

spells = {
  'cleric' => {
    '1' => %w[Cure\ Light\ Wounds Detect\ Evil Detect\ Magic Light Protection\ from\ Evil Purify\ Food\ and\ Water Remove\ Fear Resist\ Cold],
    '2' => %w[Bless Find\ Traps Hold\ Person Know\ Alignment Resist\ Fire Silence\ 15'\ Radius Snake\ Charm Speak\ with\ Animals],
    '3' => %w[Continual\ Light Cure\ Disease Growth\ of\ Animal Locate\ Object Remove\ Curse Striking],
    '4' => %w[Create\ Water Cure\ Serious\ Wounds Neutralize\ Poison Protection\ from\ Evil\ 10'\ Radius Speak\ with\ Plants Sticks\ to\ Snakes],
    '5' => %w[Commune Create\ Food Dispel\ Evil Insect\ Plague Quest Raise\ Dead]
  },
  'druid' => {
    '1' => %w[Animal\ Friendship Detect\ Danger Entangle Faerie\ Fire Invisibility\ to\ Animals Locate\ Plant\ or\ Animal Predict\ Weather Speak\ with\ Animals],
    '2' => %w[Barkskin Create\ Water Cure\ Light\ Wounds Heat\ Metal Obscuring\ Mist Produce\ Flame Slow\ Poison Warp\ Wood],
    '3' => %w[Call\ Lightning Growth\ of\ Nature Hold\ Animal Protection\ from\ Poison Tree\ Shape Water\ Breathing],
    '4' => %w[Cure\ Serious\ Wounds Dispel\ Magic Protection\ from\ Fire\ and\ Lightning Speak\ with\ Plants Summon\ Animals Temperature\ Control],
    '5' => %w[Commune\ with\ Nature Control\ Weather Pass\ Plant Protection\ from\ Plants\ and\ Animals Transmute\ Rock\ to\ Mud]
  },
  'magic_user' => {
    '1' => %w[Charm\ Person Detect\ Magic Floating\ Disc Hold\ Portal Light Magic\ Missile Protection\ from\ Evil Read\ Languages Read\ Magic Shield Sleep Ventriloquism],
    '2' => %w[Continual\ Light Detect\ Evil Detect\ Invisible ESP Invisibility Knock Levitate Locate\ Object Mirror\ Image Phantasmal\ Force Web Wizard\ Lock],
    '3' => %w[Clairvoyance Dispel\ Magic Fire\ Ball Fly Haste Hold\ Person Infravision Invisibility\ 10'\ Radius Lightning\ Bolt Protection\ from\ Evil\ 10'\ Radius Protection\ from\ Normal\ Missiles Water\ Breathing]
  },
  'illusionist' => {
    '1' => %w[Auditory\ Illusion Chromatic\ Orb Colour\ Spray Dancing\ Lights Detect\ Illusion Glamour Hypnotism Light Phantasmal\ Force Read\ Magic Spook Wall\ of\ Fog],
    '2' => %w[Blindness/Deafness Blur Detect\ Magic False\ Aura Fascinate Hypnotic\ Pattern Improved\ Phantasmal\ Force Invisibility Magic\ Mouth Mirror\ Image Quasimorph Whispering\ Wind]
  },
  'necromancer' => {
    '1' => %w[Chill\ Touch Command\ Dead Corpse\ Visage Decay Deathlight Detect\ Undead Marionette Pass\ Undead Protection\ From\ Evil Read\ Magic Skull\ Speech Undead\ Servitor],
    '2' => %w[Bone\ Armour Choke Death\ Recall Detect\ Magic Feign\ Death Paralysing\ Touch Seal\ Tomb Skeletal\ Steed Skull\ Sight Silence\ 15'\ Radius Speak\ With\ Dead Spectral\ Hand]
  }
}

write_yaml(File.join(CONFIG_DIR, 'osr_spells.yml'), { 'osr' => { 'spells' => spells } })

puts 'Done.'

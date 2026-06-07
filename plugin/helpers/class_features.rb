module AresMUSH
  module OsrRpg
    module ClassFeatures
      def self.class_flag(char, flag)
        cfg = Tables.class_config(char.osr_class)
        return nil unless cfg
        Tables.val(cfg, flag)
      end

      def self.has_backstab?(char)
        cfg = Tables.class_config(char.osr_class)
        return false unless cfg
        details = Tables.class_details(char.osr_class)
        abilities = Tables.val(details, 'special_abilities') || []
        class_flag(char, 'backstab').present? ||
          abilities.any? { |a| a.to_s.match?(/backstab/i) }
      end

      def self.can_turn_undead?(char)
        level = char.osr_level || 1
        from_level = class_flag(char, 'turn_undead_from_level')
        return false unless from_level
        level >= from_level.to_i
      end

      def self.can_track?(char)
        char.osr_class.to_s == 'ranger'
      end

      def self.tracking_target(char)
        cfg = Tables.class_config(char.osr_class)
        return 20 unless cfg
        (Tables.val(cfg, 'tracking_base') || 20).to_i
      end

      def self.turn_target(char, undead_hd)
        tables = Global.read_config('osr', 'turn_undead') || {}
        key = char.osr_class.to_s == 'paladin' ? 'paladin' : 'cleric'
        table = tables[key] || tables[key.to_sym] || {}
        level = char.osr_level || 1
        cap = table.keys.map(&:to_i).max || level
        lvl_key = [level, cap].min.to_s
        base = (table[lvl_key] || table[level.to_s] || 20).to_i
        [base - undead_hd.to_i, 3].max
      end

      def self.backstab_multiplier(char)
        level = char.osr_level || 1
        return 4 if level >= 13
        return 3 if level >= 9
        return 2 if level >= 5
        2
      end

      def self.roll_exploration(char, skill_key)
        defn = Chargen::EXPLORATION_SKILLS.find { |d| d[:key] == skill_key.to_s || d[:code].to_s.downcase == skill_key.to_s.downcase }
        return { error: t('osr_rpg.invalid_exploration_skill', skill: skill_key) } unless defn

        details = Tables.class_details(char.osr_class)
        special = Tables.val(details, 'special_abilities') || []
        chance = Chargen.resolve_exploration_chance(char, defn, special)
        roll = rand(1..6)
        success = roll <= chance
        {
          roll: roll,
          chance: chance,
          skill: defn[:name],
          success: success,
          message: t('osr_rpg.scene_roll_exploration',
                     name: char.name,
                     skill: defn[:name],
                     roll: roll,
                     chance: chance,
                     result: success ? t('osr_rpg.roll_success') : t('osr_rpg.roll_failure'))
        }
      end

      def self.roll_backstab(char, target_ac = nil)
        return { error: t('osr_rpg.backstab_not_allowed') } unless has_backstab?(char)

        result = Rolls.roll_attack(char, target_ac: target_ac)
        mult = backstab_multiplier(char)
        result[:multiplier] = mult
        if target_ac
          hit_text = result[:hit] ? t('osr_rpg.roll_hit') : t('osr_rpg.roll_miss')
          result[:message] = t('osr_rpg.scene_roll_backstab',
                               name: char.name,
                               roll: result[:roll],
                               ac: target_ac,
                               hit: hit_text,
                               multiplier: mult)
        else
          result[:message] = "#{t('osr_rpg.scene_roll_attack', name: char.name, roll: result[:roll], thac0: result[:thac0])} (x#{mult} backstab)"
        end
        result
      end

      def self.roll_turn(char, undead_hd)
        return { error: t('osr_rpg.turn_not_allowed') } unless can_turn_undead?(char)

        target = turn_target(char, undead_hd)
        roll = rand(1..20)
        success = roll >= target
        {
          roll: roll,
          target: target,
          hd: undead_hd.to_i,
          success: success,
          message: t('osr_rpg.scene_roll_turn',
                     name: char.name,
                     roll: roll,
                     target: target,
                     hd: undead_hd,
                     result: success ? t('osr_rpg.roll_success') : t('osr_rpg.roll_failure'))
        }
      end

      def self.roll_track(char, target = nil)
        return { error: t('osr_rpg.track_not_allowed') } unless can_track?(char)

        target ||= tracking_target(char)
        wis = char.osr_ability_scores['wis'] || char.osr_ability_scores[:wis]
        mod = Tables.ability_modifier(wis.to_i)
        roll = rand(1..20)
        total = roll + mod
        success = total >= target.to_i
        {
          roll: roll,
          modifier: mod,
          total: total,
          target: target.to_i,
          success: success,
          message: t('osr_rpg.scene_roll_track',
                     name: char.name,
                     roll: roll,
                     mod: mod >= 0 ? "+#{mod}" : mod.to_s,
                     total: total,
                     target: target,
                     result: success ? t('osr_rpg.roll_success') : t('osr_rpg.roll_failure'))
        }
      end
    end
  end
end

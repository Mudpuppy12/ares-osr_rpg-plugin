module AresMUSH
  module OsrRpg
    module Tables
      def self.val(h, key)
        return nil unless h
        h[key] || h[key.to_s] || h[key.to_sym]
      end

      HUMAN_CLASSES = %w[
        acrobat assassin barbarian bard cleric druid fighter
        illusionist knight magic_user paladin ranger thief necromancer
      ].freeze

      ARCANE_TRADITIONS = %w[magic_user illusionist necromancer].freeze

      def self.all_classes
        Global.read_config('osr', 'classes') || {}
      end

      def self.class_config(key)
        return nil if key.blank?
        all_classes[key.to_s] || all_classes[key.to_sym]
      end

      def self.class_details(key)
        details = Global.read_config('osr', 'class_details') || {}
        val(details, key.to_s) || {}
      end

      def self.class_groups
        Global.read_config('osr', 'class_groups') || %w[human demihuman supplemental]
      end

      def self.abilities
        Global.read_config('osr', 'abilities') || %w[str dex con int wis cha]
      end

      def self.alignments
        Global.read_config('osr', 'alignments') || ['Law', 'Neutrality', 'Chaos']
      end

      def self.ability_modifier(score)
        return 0 if score.nil?
        mods = Global.read_config('osr', 'ability_modifiers') || {}
        mods[score.to_s] || mods[score.to_i.to_s] || 0
      end

      def self.thief_skills_config
        Global.read_config('osr', 'thief_skills_d6') || {}
      end

      def self.thief_skill_keys
        thief_skills_config['skills'] || []
      end

      def self.base_thief_chance
        thief_skills_config['base_chance'] || 1
      end

      def self.max_thief_chance
        thief_skills_config['max_chance'] || 5
      end

      def self.l1_expertise_points
        per_level = thief_skills_config['expertise_per_level'] || {}
        per_level['1'] || per_level[1] || 4
      end

      def self.skill_set_for_class(class_key)
        cfg = class_config(class_key)
        return [] unless cfg
        set = val(cfg, 'skill_set')
        return thief_skill_keys if set == 'all_eight'
        set || []
      end

      def self.allowed_alignments(class_key)
        cfg = class_config(class_key)
        return alignments unless cfg
        restrictions = val(cfg, 'alignment_restrictions')
        return alignments if restrictions.nil? || restrictions.empty?
        restrictions
      end

      def self.progression_row(class_key, level)
        cfg = class_config(class_key)
        return nil unless cfg
        progression = val(cfg, 'progression') || []
        progression.find { |r| val(r, 'level') == level }
      end

      def self.spell_tradition(class_key)
        cfg = class_config(class_key)
        cfg ? val(cfg, 'spell_tradition') : nil
      end

      def self.spells_for_tradition(tradition)
        return {} if tradition.blank?
        Global.read_config('osr', 'spells', tradition) || {}
      end

      def self.prime_req_xp_bonus(class_key, scores)
        cfg = class_config(class_key)
        return 0 unless cfg
        primes = val(cfg, 'prime_reqs') || []
        return 0 if primes.empty?

        bonuses = []
        primes.each do |req|
          score = scores[req].to_i
          if score >= 16
            bonuses << 10
          elsif score >= 13
            bonuses << 5
          elsif score <= 8
            bonuses << -10
          elsif score <= 11
            bonuses << 0
          else
            bonuses << 0
          end
        end
        bonuses.sum / primes.length
      end

      def self.allowed_class_keys
        list = Global.read_config('osr_rpg', 'allowed_classes') || []
        list = list.map(&:to_s).reject(&:blank?)
        list.empty? ? nil : list
      end

      def self.class_allowed?(key)
        allowed = allowed_class_keys
        return true if allowed.nil?
        allowed.include?(key.to_s)
      end

      def self.casting_type(class_key)
        cfg = class_config(class_key)
        return nil unless cfg
        tradition = val(cfg, 'spell_tradition')
        return nil if tradition.blank?
        return 'restricted' if val(cfg, 'l1_spells').present?
        ARCANE_TRADITIONS.include?(tradition.to_s) ? 'arcane' : 'divine'
      end

      def self.expertise_points_for_level(level)
        per_level = thief_skills_config['expertise_per_level'] || {}
        val = per_level[level.to_s] || per_level[level.to_i]
        return val.to_i if val
        (per_level['default'] || 2).to_i
      end

      def self.l1_spell_slot_count(class_key)
        row = progression_row(class_key, 1)
        return 0 unless row
        slots = val(row, 'spell_slots') || {}
        slots.values.map(&:to_i).sum
      end

      def self.restricted_l1_spells(class_key)
        cfg = class_config(class_key)
        return [] unless cfg
        (val(cfg, 'l1_spells') || []).map { |s| s.to_s.titleize }
      end

      def self.arcane_l1_spell_names(class_key)
        return [] unless casting_type(class_key) == 'arcane'
        tradition = spell_tradition(class_key)
        spells = spells_for_tradition(tradition)
        spells['1'] || spells[1] || []
      end

      def self.grouped_classes_for_web
        groups = class_groups
        classes = all_classes
        groups.map do |group|
          entries = classes.select { |_k, v| val(v, 'group') == group }.map do |key, cfg|
            next unless class_allowed?(key.to_s)
            l1_row = progression_row(key.to_s, 1)
            l1_saves_raw = l1_row ? val(l1_row, 'saves') : nil
            l1_saves = if l1_saves_raw.present?
                         %w[death wands paralysis breath spells].each_with_object({}) do |cat, h|
                           v = val(l1_saves_raw, cat)
                           h[cat] = v unless v.nil?
                         end.presence
                       end
            details = class_details(key.to_s)
            {
              key: key.to_s,
              name: val(cfg, 'name') || key.to_s.titleize,
              race: val(cfg, 'race'),
              blurb: val(cfg, 'blurb'),
              hd: val(cfg, 'hd'),
              l1_thac0: l1_row ? val(l1_row, 'thac0') : nil,
              l1_saves: l1_saves,
              armor: val(details, 'armor') || val(cfg, 'armor'),
              weapons: val(details, 'weapons'),
              languages: val(details, 'languages') || [],
              restrictions: val(details, 'restrictions') || [],
              special_abilities: val(details, 'special_abilities') || [],
              max_level: val(cfg, 'max_level'),
              prime_reqs: val(cfg, 'prime_reqs') || [],
              min_scores: val(cfg, 'min_scores') || {},
              alignment_restrictions: val(cfg, 'alignment_restrictions'),
              skill_system: val(cfg, 'skill_system'),
              skill_set: skill_set_for_class(key.to_s),
              l1_expertise_points: val(cfg, 'l1_expertise_points'),
              spells_from_level: val(cfg, 'spells_from_level'),
              spell_tradition: val(cfg, 'spell_tradition'),
              casting_type: casting_type(key.to_s),
              l1_spell_slots: l1_spell_slot_count(key.to_s),
              l1_spells: restricted_l1_spells(key.to_s),
              spell_list_l1: arcane_l1_spell_names(key.to_s),
              playtest: val(cfg, 'playtest')
            }
          end.compact.sort_by { |e| e[:name] }
          {
            group: group,
            label: group.titleize,
            classes: entries
          }
        end.reject { |g| g[:classes].empty? }
      end

      def self.roll_3d6
        roll_3d6_detail[:total]
      end

      def self.roll_3d6_detail
        dice = 3.times.map { rand(1..6) }
        { dice: dice, total: dice.sum }
      end

      def self.parse_key_value_pairs(args_string)
        return {} if args_string.blank?
        pairs = {}
        args_string.to_s.split(/[\s\/]+/).each do |part|
          next unless part.include?('=')
          key, val = part.split('=', 2)
          next if key.blank? || val.blank?
          pairs[normalize_key(key)] = val.strip
        end
        pairs
      end

      def self.normalize_key(key)
        key.to_s.strip.downcase.gsub(/\s+/, '_')
      end

      def self.hp_per_level_mode
        mode = Global.read_config('osr_rpg', 'hp_per_level').to_s.downcase
        mode == 'roll' ? 'roll' : 'max'
      end

      def self.con_modifier_for(char)
        scores = char.osr_ability_scores || {}
        ability_modifier(scores['con'] || scores[:con])
      end

      def self.hp_gain(hd_die, con_mod)
        die = hd_die.to_s.gsub('d', '').to_i
        if hp_per_level_mode == 'max'
          [die + con_mod.to_i, 1].max
        else
          roll_hd(hd_die, con_mod)
        end
      end

      def self.roll_hd(hd_die, con_mod)
        die = hd_die.to_s.gsub('d', '').to_i
        roll = rand(1..die) + con_mod
        [roll, 1].max
      end

      def self.roll_starting_gold
        (1..3).sum { rand(1..6) } * 10
      end

      def self.human_class?(class_key)
        HUMAN_CLASSES.include?(class_key.to_s)
      end

      def self.race_for_class(class_key)
        cfg = class_config(class_key)
        cfg ? val(cfg, 'race') : nil
      end
    end
  end
end

module AresMUSH
  module Rpg
    module Tables
      def self.val(h, key)
        return nil unless h
        h[key] || h[key.to_s] || h[key.to_sym]
      end

      HUMAN_CLASSES = %w[
        acrobat assassin barbarian bard cleric druid fighter
        illusionist knight magic_user paladin ranger thief necromancer
      ].freeze

      def self.all_classes
        Global.read_config('ose', 'classes') || {}
      end

      def self.class_config(key)
        return nil if key.blank?
        all_classes[key.to_s] || all_classes[key.to_sym]
      end

      def self.class_groups
        Global.read_config('ose', 'class_groups') || %w[human demihuman supplemental]
      end

      def self.abilities
        Global.read_config('ose', 'abilities') || %w[str dex con int wis cha]
      end

      def self.alignments
        Global.read_config('ose', 'alignments') || ['Law', 'Neutrality', 'Chaos']
      end

      def self.ability_modifier(score)
        return 0 if score.nil?
        mods = Global.read_config('ose', 'ability_modifiers') || {}
        mods[score.to_s] || mods[score.to_i.to_s] || 0
      end

      def self.thief_skills_config
        Global.read_config('ose', 'thief_skills_d6') || {}
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
        Global.read_config('ose', 'spells', tradition) || {}
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

      def self.grouped_classes_for_web
        groups = class_groups
        classes = all_classes
        groups.map do |group|
          entries = classes.select { |_k, v| val(v, 'group') == group }.map do |key, cfg|
            {
              key: key.to_s,
              name: val(cfg, 'name') || key.to_s.titleize,
              blurb: val(cfg, 'blurb'),
              hd: val(cfg, 'hd'),
              max_level: val(cfg, 'max_level'),
              prime_reqs: val(cfg, 'prime_reqs') || [],
              min_scores: val(cfg, 'min_scores') || {},
              alignment_restrictions: val(cfg, 'alignment_restrictions'),
              skill_system: val(cfg, 'skill_system'),
              skill_set: skill_set_for_class(key.to_s),
              l1_expertise_points: val(cfg, 'l1_expertise_points'),
              spells_from_level: val(cfg, 'spells_from_level'),
              spell_tradition: val(cfg, 'spell_tradition'),
              playtest: val(cfg, 'playtest')
            }
          end.sort_by { |e| e[:name] }
          {
            group: group,
            label: group.titleize,
            classes: entries
          }
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

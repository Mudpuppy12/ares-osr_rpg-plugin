module AresMUSH
  module Rpg
    module Chargen
      def self.save_char(char, data)
        alerts = []
        class_key = data['class']
        alignment = data['alignment']
        scores = normalize_scores(data['ability_scores'] || {})
        thief_skills = data['thief_skills'] || {}

        alerts.concat validate(class_key, alignment, scores, thief_skills)
        return alerts if alerts.any?

        apply_sheet(char, class_key, alignment, scores, thief_skills)
        []
      end

      def self.normalize_scores(raw)
        Tables.abilities.each_with_object({}) do |ab, h|
          h[ab] = raw[ab].to_i if raw[ab]
        end
      end

      def self.validate(class_key, alignment, scores, thief_skills)
        alerts = []
        cfg = Tables.class_config(class_key)

        if class_key.blank?
          alerts << t('rpg.class_not_set')
          return alerts
        end
        if cfg.nil?
          alerts << t('rpg.invalid_class', class: class_key)
          return alerts
        end
        if alignment.blank?
          alerts << t('rpg.alignment_not_set')
        elsif !Tables.allowed_alignments(class_key).include?(alignment)
          alerts << t('rpg.invalid_alignment', alignment: alignment)
        end

        Tables.abilities.each do |ab|
          if scores[ab].nil? || scores[ab] == 0
            alerts << t('rpg.ability_not_set', ability: ab.upcase)
          end
        end

        (Tables.val(cfg, 'min_scores') || {}).each do |ab, min|
          score = scores[ab].to_i
          if score > 0 && score < min.to_i
            alerts << t('rpg.min_score_failed', ability: ab.upcase, score: score, min: min, class: Tables.val(cfg, 'name'))
          end
        end

        if Tables.val(cfg, 'skill_system') == 'd6' && Tables.val(cfg, 'l1_expertise_points')
          alerts.concat validate_thief_allocation(thief_skills, Tables.val(cfg, 'l1_expertise_points').to_i)
        end

        alerts
      end

      def self.validate_thief_allocation(thief_skills, required_points)
        alerts = []
        spent = thief_skills.values.map(&:to_i).sum
        if spent != required_points
          alerts << t('rpg.thief_points_wrong', points: required_points, spent: spent)
        end
        base = Tables.base_thief_chance
        max = Tables.max_thief_chance
        thief_skills.each do |skill, points|
          chance = base + points.to_i
          if chance > max
            alerts << t('rpg.thief_skill_too_high', skill: skill.titleize, max: max)
          end
        end
        alerts
      end

      def self.apply_sheet(char, class_key, alignment, scores, thief_skills)
        cfg = Tables.class_config(class_key)
        row = Tables.progression_row(class_key, 1)
        con_mod = Tables.ability_modifier(scores['con'])
        hp = Tables.roll_hd(Tables.val(cfg, 'hd'), con_mod)

        final_thief_skills = build_thief_skills(class_key, thief_skills)

        char.update(
          ose_class: class_key,
          ose_level: 1,
          ose_xp: 0,
          ose_alignment: alignment,
          ose_ability_scores: scores,
          ose_hp: hp,
          ose_hp_max: hp,
          ose_thac0: row ? Tables.val(row, 'thac0') : nil,
          ose_saving_throws: row ? (Tables.val(row, 'saves') || {}) : {},
          ose_spell_slots: row ? (Tables.val(row, 'spell_slots') || {}) : {},
          ose_thief_skills: final_thief_skills,
          ose_xp_bonus: Tables.prime_req_xp_bonus(class_key, scores),
          ose_starting_gold: char.ose_starting_gold || Tables.roll_starting_gold
        )
      end

      def self.build_thief_skills(class_key, allocated)
        cfg = Tables.class_config(class_key)
        return {} unless cfg && Tables.val(cfg, 'skill_system') == 'd6'

        base = Tables.base_thief_chance
        skills = Tables.skill_set_for_class(class_key)
        result = {}
        skills.each do |skill|
          extra = allocated[skill].to_i
          result[skill] = base + extra
        end
        result
      end

      def self.sheet_for_web_editing(char, _enactor)
        scores = Tables.abilities.each_with_object({}) do |ab, h|
          h[ab] = char.ose_ability_scores[ab]
        end
        {
          class: char.ose_class,
          alignment: char.ose_alignment,
          ability_scores: scores,
          thief_skills: char.ose_thief_skills,
          thief_skill_allocations: thief_allocations_from_stored(char),
          class_groups: Tables.grouped_classes_for_web,
          alignments: Tables.alignments,
          abilities: Tables.abilities,
          thief_skill_defs: thief_skill_defs,
          l1_expertise_points: Tables.l1_expertise_points,
          sheet: build_sheet_display(char)
        }
      end

      def self.thief_allocations_from_stored(char)
        base = Tables.base_thief_chance
        char.ose_thief_skills.each_with_object({}) do |(skill, chance), h|
          h[skill] = [chance.to_i - base, 0].max
        end
      end

      def self.thief_skill_defs
        Tables.thief_skill_keys.map do |key|
          { key: key, name: key.titleize.gsub('In ', 'in ') }
        end
      end

      def self.sheet_for_web_viewing(char, _enactor)
        build_sheet_display(char)
      end

      def self.build_sheet_display(char)
        class_key = char.ose_class
        cfg = Tables.class_config(class_key)
        row = Tables.progression_row(class_key, char.ose_level || 1)
        tradition = Tables.spell_tradition(class_key)
        spells = tradition ? Tables.spells_for_tradition(tradition) : {}

        thief_display = char.ose_thief_skills.map do |skill, chance|
          { key: skill, name: skill.titleize.gsub('In ', 'in '), chance: "#{chance}-in-6" }
        end

        ability_display = Tables.abilities.map do |ab|
          score = char.ose_ability_scores[ab].to_i
          {
            key: ab,
            name: ab.upcase,
            score: score,
            modifier: Tables.ability_modifier(score)
          }
        end

        {
          class_key: class_key,
          class_name: cfg ? Tables.val(cfg, 'name') : nil,
          race: cfg ? Tables.val(cfg, 'race') : nil,
          group: cfg ? Tables.val(cfg, 'group') : nil,
          level: char.ose_level || 1,
          xp: char.ose_xp || 0,
          xp_bonus: char.ose_xp_bonus || 0,
          alignment: char.ose_alignment,
          hd: cfg ? Tables.val(cfg, 'hd') : nil,
          hp: char.ose_hp,
          hp_max: char.ose_hp_max,
          thac0: char.ose_thac0,
          saves: char.ose_saving_throws,
          spell_slots: char.ose_spell_slots,
          spell_tradition: tradition,
          spells: spells,
          thief_skills: thief_display,
          abilities: ability_display,
          starting_gold: char.ose_starting_gold,
          blurb: cfg ? Tables.val(cfg, 'blurb') : nil,
          playtest: cfg ? Tables.val(cfg, 'playtest') : nil,
          hd_display: row ? Tables.val(row, 'hd') : nil
        }
      end

      def self.app_review(char)
        lines = []
        sheet = build_sheet_display(char)

        if sheet[:class_name].blank?
          return AresMUSH::Chargen.format_review_status 'OSE Sheet', t('rpg.class_not_set')
        end

        lines << "%xg#{sheet[:class_name]}%xn (#{sheet[:race]}) - Level #{sheet[:level]}"
        lines << "Alignment: #{sheet[:alignment] || 'Not set'}"
        lines << "HP: #{sheet[:hp]}/#{sheet[:hp_max]}  THAC0: #{sheet[:thac0]}  XP Bonus: #{sheet[:xp_bonus]}%"
        lines << "Gold: #{sheet[:starting_gold]} gp"

        if sheet[:abilities]
          ab_line = sheet[:abilities].map do |a|
            mod = a[:modifier]
            mod_str = mod >= 0 ? "+#{mod}" : mod.to_s
            "#{a[:name]} #{a[:score]}(#{mod_str})"
          end.join('  ')
          lines << ab_line
        end

        if sheet[:saves] && !sheet[:saves].empty?
          s = sheet[:saves]
          lines << "Saves: D#{s[:death] || s['death']} W#{s[:wands] || s['wands']} P#{s[:paralysis] || s['paralysis']} B#{s[:breath] || s['breath']} S#{s[:spells] || s['spells']}"
        end

        if sheet[:spell_slots] && !sheet[:spell_slots].empty?
          slots = sheet[:spell_slots].map { |lvl, n| "L#{lvl}:#{n}" }.join(' ')
          lines << "Spell slots: #{slots}"
        end

        if sheet[:thief_skills] && !sheet[:thief_skills].empty?
          skills = sheet[:thief_skills].map { |sk| "#{sk[:name]} #{sk[:chance]}" }.join(', ')
          lines << "Skills: #{skills}"
        end

        status = lines.join('%r')
        AresMUSH::Chargen.format_review_status 'OSE Sheet', status
      end
    end
  end
end

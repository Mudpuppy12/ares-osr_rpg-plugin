module AresMUSH
  module OsrRpg
    module Chargen
      def self.save_char(char, data)
        merge_ability_roll_count(char, data['ability_roll_count'])
        ensure_starting_gold!(char)

        class_key = data['class']
        alignment = data['alignment']
        scores = normalize_scores(data['ability_scores'] || {})
        thief_skills = data['thief_skills'] || {}
        spell_book = data['spell_book'] || {}
        inventory = data['inventory'] || {}

        alerts = validate(char, class_key, alignment, scores, thief_skills, spell_book, inventory)
        return alerts if alerts.any?

        apply_sheet(char, class_key, alignment, scores, thief_skills, spell_book, inventory)
        []
      end

      def self.set_class(char, key)
        return t('osr_rpg.invalid_class', class: key) if key.blank?
        return t('osr_rpg.invalid_class', class: key) if Tables.class_config(key).nil?
        return t('osr_rpg.class_not_allowed', class: key) unless Tables.class_allowed?(key)
        char.update(osr_class: key.to_s)
        nil
      end

      def self.class_change_allowed?(char, class_key)
        return true if Tables.class_allowed?(class_key)
        char.osr_class.to_s == class_key.to_s
      end

      def self.set_alignment(char, value)
        return t('osr_rpg.alignment_not_set') if value.blank?
        char.update(osr_alignment: value.to_s)
        nil
      end

      def self.increment_ability_roll_count(char, by: 1)
        count = (char.osr_ability_roll_count || 0) + by
        char.update(osr_ability_roll_count: count)
        count
      end

      def self.merge_ability_roll_count(char, submitted)
        return if submitted.nil?

        current = char.osr_ability_roll_count || 0
        new_count = [submitted.to_i, current].max
        char.update(osr_ability_roll_count: new_count) if new_count > current
      end

      def self.roll_abilities(char, abilities = nil)
        increment_ability_roll_count(char)
        to_roll = abilities || Tables.abilities
        scores = (char.osr_ability_scores || {}).dup
        rolled = {}
        to_roll.each do |ab|
          key = ab.to_s
          score = Tables.roll_3d6
          scores[key] = score
          rolled[key] = score
        end
        char.update(osr_ability_scores: scores)
        rolled
      end

      def self.set_abilities(char, scores_hash)
        scores = (char.osr_ability_scores || {}).dup
        errors = []
        scores_hash.each do |ab, val|
          key = ab.to_s
          unless Tables.abilities.include?(key)
            errors << t('osr_rpg.invalid_ability', ability: ab)
            next
          end
          score = val.to_i
          if score < 3 || score > 18
            errors << t('osr_rpg.invalid_ability_score', ability: key.upcase, score: score)
            next
          end
          scores[key] = score
        end
        return errors if errors.any?
        char.update(osr_ability_scores: scores)
        []
      end

      def self.set_thief_allocations(char, allocations)
        cfg = Tables.class_config(char.osr_class)
        return [t('osr_rpg.thief_class_required')] unless cfg && Tables.val(cfg, 'skill_system') == 'd6'

        allowed = Tables.skill_set_for_class(char.osr_class)
        stored = (char.osr_thief_skills || {}).dup
        errors = []

        allocations.each do |skill, points|
          key = Tables.normalize_key(skill)
          unless allowed.include?(key)
            errors << t('osr_rpg.invalid_thief_skill', skill: skill)
            next
          end
          pts = points.to_i
          if pts < 0 || pts > 4
            errors << t('osr_rpg.invalid_thief_points', skill: key, points: pts)
            next
          end
          stored[key] = pts
        end

        return errors if errors.any?
        char.update(osr_thief_skills: stored)
        []
      end

      def self.finish_char(char)
        ensure_starting_gold!(char)
        class_key = char.osr_class
        alignment = char.osr_alignment
        scores = normalize_scores(char.osr_ability_scores || {})
        thief_skills = thief_allocations_for_finish(char)
        spell_book = char.osr_spell_book || {}
        inventory = char.osr_inventory || {}

        alerts = validate(char, class_key, alignment, scores, thief_skills, spell_book, inventory)
        return alerts if alerts.any?

        apply_sheet(char, class_key, alignment, scores, thief_skills, spell_book, inventory)
        []
      end

      def self.reset_char(char)
        char.update(
          osr_class: nil,
          osr_level: 1,
          osr_xp: 0,
          osr_alignment: nil,
          osr_ability_scores: {},
          osr_hp: nil,
          osr_hp_max: nil,
          osr_thac0: nil,
          osr_saving_throws: {},
          osr_spell_slots: {},
          osr_spell_book: {},
          osr_spell_tradition: nil,
          osr_thief_skills: {},
          osr_thief_expertise_unspent: 0,
          osr_starting_gold: nil,
          osr_gold: nil,
          osr_inventory: {},
          osr_xp_bonus: 0,
          osr_ability_roll_count: 0,
          osr_ac: nil,
          osr_prepared_spells: {},
          osr_spell_slots_used: {},
          osr_equipment: []
        )
      end

      def self.spend_expertise(char, allocations)
        cfg = Tables.class_config(char.osr_class)
        return [t('osr_rpg.thief_class_required')] unless cfg && Tables.val(cfg, 'skill_system') == 'd6'
        return [t('osr_rpg.no_sheet_for_levelup')] unless CommandHelpers.sheet_applied?(char)

        allowed = Tables.skill_set_for_class(char.osr_class)
        stored = (char.osr_thief_skills || {}).dup
        unspent = char.osr_thief_expertise_unspent || 0
        errors = []
        cost = 0

        allocations.each do |skill, points|
          key = Tables.normalize_key(skill)
          unless allowed.include?(key)
            errors << t('osr_rpg.invalid_thief_skill', skill: skill)
            next
          end
          pts = points.to_i
          if pts < 0
            errors << t('osr_rpg.invalid_thief_points', skill: key, points: pts)
            next
          end
          cost += pts
          next if pts == 0
          current = stored[key].to_i
          if current + pts > Tables.max_thief_chance
            errors << t('osr_rpg.thief_skill_too_high', skill: key.titleize, max: Tables.max_thief_chance)
            next
          end
          stored[key] = current + pts
        end

        return errors if errors.any?
        return [t('osr_rpg.expertise_unspent_insufficient', unspent: unspent, cost: cost)] if cost > unspent

        char.update(osr_thief_skills: stored, osr_thief_expertise_unspent: unspent - cost)
        []
      end

      def self.thief_allocations_for_finish(char)
        return {} if char.osr_thief_skills.blank?
        if CommandHelpers.sheet_applied?(char)
          thief_allocations_from_stored(char)
        else
          char.osr_thief_skills.transform_values { |v| v.to_i }
        end
      end

      def self.normalize_scores(raw)
        Tables.abilities.each_with_object({}) do |ab, h|
          h[ab] = raw[ab].to_i if raw[ab]
        end
      end

      def self.validate(char, class_key, alignment, scores, thief_skills, spell_book = {}, inventory = {})
        alerts = []
        cfg = Tables.class_config(class_key)

        if class_key.blank?
          alerts << t('osr_rpg.class_not_set')
          return alerts
        end
        if cfg.nil?
          alerts << t('osr_rpg.invalid_class', class: class_key)
          return alerts
        end
        unless class_change_allowed?(char, class_key)
          alerts << t('osr_rpg.class_not_allowed', class: class_key)
        end
        if alignment.blank?
          alerts << t('osr_rpg.alignment_not_set')
        elsif !Tables.allowed_alignments(class_key).include?(alignment)
          alerts << t('osr_rpg.invalid_alignment', alignment: alignment)
        end

        Tables.abilities.each do |ab|
          if scores[ab].nil? || scores[ab] == 0
            alerts << t('osr_rpg.ability_not_set', ability: ab.upcase)
          end
        end

        (Tables.val(cfg, 'min_scores') || {}).each do |ab, min|
          score = scores[ab].to_i
          if score > 0 && score < min.to_i
            alerts << t('osr_rpg.min_score_failed', ability: ab.upcase, score: score, min: min, class: Tables.val(cfg, 'name'))
          end
        end

        if Tables.val(cfg, 'skill_system') == 'd6' && Tables.val(cfg, 'l1_expertise_points')
          alerts.concat validate_thief_allocation(thief_skills, Tables.val(cfg, 'l1_expertise_points').to_i)
        end

        alerts.concat validate_spell_book(class_key, spell_book)
        alerts.concat validate_inventory(class_key, inventory, char.osr_starting_gold)

        alerts
      end

      def self.validate_inventory(class_key, inventory, gold_budget)
        alerts = []
        inv = EquipmentHelper.normalize_inventory_hash(inventory)
        total = EquipmentHelper.cart_total(inv)

        inv.each_key do |key|
          alerts << t('osr_rpg.invalid_equipment', item: key) unless EquipmentHelper.lookup_item(key)
        end

        if total > gold_budget.to_i
          alerts << t('osr_rpg.cart_over_budget', total: total, budget: gold_budget)
        end

        alerts
      end

      def self.validate_spell_book(class_key, spell_book)
        alerts = []
        casting = Tables.casting_type(class_key)
        book = spell_book || {}
        l1_picks = book['1'] || book[1] || []

        case casting
        when 'arcane'
          required = Tables.l1_spell_slot_count(class_key)
          picks = Array(l1_picks).map(&:to_s).reject(&:blank?)
          if picks.length != required
            alerts << t('osr_rpg.spell_picks_wrong', required: required, picked: picks.length)
          end
          tradition = Tables.spell_tradition(class_key)
          valid = (Tables.spells_for_tradition(tradition)['1'] || []).map(&:to_s)
          picks.each do |name|
            alerts << t('osr_rpg.invalid_spell', spell: name) unless valid.include?(name)
          end
          if picks.uniq.length != picks.length
            alerts << t('osr_rpg.duplicate_spell_pick')
          end
        when 'restricted'
          required = Tables.restricted_l1_spells(class_key)
          picks = Array(l1_picks).map(&:to_s)
          if picks.sort != required.sort
            alerts << t('osr_rpg.restricted_spells_wrong', required: required.join(', '))
          end
        when 'divine', nil
          if l1_picks.present?
            alerts << t('osr_rpg.spell_book_not_allowed')
          end
        end
        alerts
      end

      def self.resolve_spell_book(class_key, spell_book)
        casting = Tables.casting_type(class_key)
        case casting
        when 'restricted'
          { '1' => Tables.restricted_l1_spells(class_key) }
        when 'arcane'
          book = spell_book || {}
          { '1' => (book['1'] || book[1] || []).map(&:to_s) }
        else
          {}
        end
      end

      def self.normalize_spell_picks(class_key, raw_spells)
        casting = Tables.casting_type(class_key)
        return [] if casting.nil?

        tradition = Tables.spell_tradition(class_key)
        if casting == 'arcane'
          valid = (Tables.spells_for_tradition(tradition)['1'] || []).map(&:to_s)
          raw_spells.map do |raw|
            key = raw.to_s.strip
            match = valid.find { |v| v.downcase == key.downcase || v.downcase.gsub(/\s+/, '_') == key.downcase.gsub(/\s+/, '_') }
            match || key.titleize
          end
        elsif casting == 'restricted'
          Tables.restricted_l1_spells(class_key)
        else
          []
        end
      end

      def self.set_spell_book(char, raw_spells)
        class_key = char.osr_class
        return t('osr_rpg.class_not_set') if class_key.blank?

        casting = Tables.casting_type(class_key)
        return t('osr_rpg.spell_info_none') if casting.nil?
        return t('osr_rpg.spell_info_divine', tradition: Tables.spell_tradition(class_key).to_s.titleize) if casting == 'divine'

        picks = normalize_spell_picks(class_key, raw_spells)
        book = { '1' => picks }
        alerts = validate_spell_book(class_key, book)
        return alerts if alerts.any?

        tradition = Tables.spell_tradition(class_key)
        char.update(osr_spell_book: book, osr_spell_tradition: tradition)
        true
      end

      def self.validate_thief_allocation(thief_skills, required_points)
        alerts = []
        spent = thief_skills.values.map(&:to_i).sum
        if spent != required_points
          alerts << t('osr_rpg.thief_points_wrong', points: required_points, spent: spent)
        end
        base = Tables.base_thief_chance
        max = Tables.max_thief_chance
        thief_skills.each do |skill, points|
          chance = base + points.to_i
          if chance > max
            alerts << t('osr_rpg.thief_skill_too_high', skill: skill.titleize, max: max)
          end
        end
        alerts
      end

      def self.apply_sheet(char, class_key, alignment, scores, thief_skills, spell_book = {}, inventory = {})
        cfg = Tables.class_config(class_key)
        row = Tables.progression_row(class_key, 1)
        con_mod = Tables.ability_modifier(scores['con'])
        hp = Tables.hp_gain(Tables.val(cfg, 'hd'), con_mod)

        final_thief_skills = build_thief_skills(class_key, thief_skills)
        final_spell_book = resolve_spell_book(class_key, spell_book)
        tradition = Tables.spell_tradition(class_key)

        starting_gold = char.osr_starting_gold
        purchase = EquipmentHelper.purchase_items(char, inventory, budget: starting_gold)
        final_inventory = purchase[:inventory] || {}
        gold_remaining = purchase[:error] ? starting_gold : purchase[:gold_remaining]

        char.update(
          osr_class: class_key,
          osr_level: 1,
          osr_xp: 0,
          osr_alignment: alignment,
          osr_ability_scores: scores,
          osr_hp: hp,
          osr_hp_max: hp,
          osr_thac0: row ? Tables.val(row, 'thac0') : nil,
          osr_saving_throws: row ? (Tables.val(row, 'saves') || {}) : {},
          osr_spell_slots: row ? (Tables.val(row, 'spell_slots') || {}) : {},
          osr_spell_book: final_spell_book,
          osr_spell_tradition: tradition,
          osr_thief_skills: final_thief_skills,
          osr_thief_expertise_unspent: 0,
          osr_xp_bonus: Tables.prime_req_xp_bonus(class_key, scores),
          osr_starting_gold: starting_gold,
          osr_gold: gold_remaining,
          osr_inventory: final_inventory,
          osr_ac: CommandHelpers.default_ac,
          osr_prepared_spells: {},
          osr_spell_slots_used: {},
          osr_equipment: []
        )
        EquipmentHelper.auto_equip_from_inventory(char)
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

      def self.ensure_starting_gold!(char)
        return if char.osr_starting_gold

        char.update(osr_starting_gold: Tables.roll_starting_gold)
      end

      def self.sheet_for_web_editing(char, _enactor)
        EquipmentHelper.migrate_character!(char)
        ensure_starting_gold!(char)
        scores = Tables.abilities.each_with_object({}) do |ab, h|
          h[ab] = char.osr_ability_scores[ab]
        end
        class_key = char.osr_class
        tradition = class_key ? Tables.spell_tradition(class_key) : nil
        casting = class_key ? Tables.casting_type(class_key) : nil
        spell_lists = {}
        if tradition && casting == 'arcane'
          all_spells = Tables.spells_for_tradition(tradition)
          spell_lists = { '1' => all_spells['1'] || all_spells[1] || [] }
        end
        starting_gold = char.osr_starting_gold
        inventory = EquipmentHelper.normalize_inventory_hash(char.osr_inventory)
        cart_total = EquipmentHelper.cart_total(inventory)
        {
          class: class_key,
          alignment: char.osr_alignment,
          ability_scores: scores,
          thief_skills: char.osr_thief_skills,
          thief_skill_allocations: thief_allocations_from_stored(char),
          spell_book: char.osr_spell_book || {},
          casting_type: casting,
          l1_spell_slots: class_key ? Tables.l1_spell_slot_count(class_key) : 0,
          l1_spells: class_key ? Tables.restricted_l1_spells(class_key) : [],
          spell_lists: spell_lists,
          class_groups: Tables.grouped_classes_for_web,
          alignments: Tables.alignments,
          abilities: Tables.abilities,
          thief_skill_defs: thief_skill_defs,
          l1_expertise_points: Tables.l1_expertise_points,
          ability_modifiers: Global.read_config('osr', 'ability_modifiers') || {},
          require_server_rolls: Global.read_config('osr_rpg', 'require_server_rolls') != false,
          ability_roll_count: char.osr_ability_roll_count || 0,
          hp_per_level: Tables.hp_per_level_mode,
          equipment_catalog: ReferenceData.equipment_for_web,
          starting_gold: starting_gold,
          gold: char.osr_gold,
          inventory: inventory,
          cart_total: cart_total,
          gold_remaining: starting_gold - cart_total,
          class_equipment_notes: EquipmentHelper.class_equipment_notes(class_key),
          sheet: build_sheet_display(char)
        }
      end

      def self.thief_allocations_from_stored(char)
        return {} if char.osr_thief_skills.blank?
        if CommandHelpers.sheet_applied?(char)
          base = Tables.base_thief_chance
          char.osr_thief_skills.each_with_object({}) do |(skill, chance), h|
            h[skill] = [chance.to_i - base, 0].max
          end
        else
          char.osr_thief_skills.transform_values { |v| v.to_i }
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

      EXPLORATION_THIEF_KEYS = %w[hear_noise find_remove_traps].freeze

      EXPLORATION_SKILLS = [
        {
          code: 'LD',
          key: 'listen_at_door',
          name: 'Listen at door',
          thief_key: 'hear_noise',
          patterns: [/listen\s+at\s+doors?/i]
        },
        {
          code: 'OD',
          key: 'open_stuck_door',
          name: 'Open stuck door',
          thief_key: nil,
          patterns: [/open\s+stuck\s+doors?/i]
        },
        {
          code: 'SD',
          key: 'find_secret_door',
          name: 'Find secret door',
          thief_key: nil,
          patterns: [/detect\s+secret\s+doors?/i, /find\s+secret\s+doors?/i]
        },
        {
          code: 'FT',
          key: 'find_room_trap',
          name: 'Find room trap',
          thief_key: 'find_remove_traps',
          patterns: [/detect\s+room\s+traps?/i, /find\s+room\s+traps?/i]
        }
      ].freeze

      def self.parse_chance_in6(text)
        match = text.to_s.match(/(\d)-in-6/i)
        match ? match[1].to_i : nil
      end

      def self.thief_skill_chance_for(char, skill_key)
        skills = char.osr_thief_skills || {}
        key = Tables.normalize_key(skill_key)
        val = skills[key] || skills[key.to_sym]
        return nil if val.nil?

        base = Tables.base_thief_chance
        if CommandHelpers.sheet_applied?(char)
          val.to_i
        else
          base + val.to_i
        end
      end

      def self.resolve_exploration_chance(char, defn, special_abilities)
        chance = Tables.base_thief_chance

        if defn[:thief_key]
          thief_chance = thief_skill_chance_for(char, defn[:thief_key])
          chance = thief_chance if thief_chance && thief_chance > chance
        end

        special_abilities.each do |ability|
          next unless defn[:patterns].any? { |pattern| ability.match?(pattern) }

          ability_chance = parse_chance_in6(ability) || 2
          chance = ability_chance if ability_chance > chance
        end

        chance
      end

      def self.build_exploration_display(char, special_abilities)
        special_abilities ||= []
        EXPLORATION_SKILLS.map do |defn|
          chance = resolve_exploration_chance(char, defn, special_abilities)
          {
            code: defn[:code],
            key: defn[:key],
            name: defn[:name],
            chance: "#{chance}-in-6"
          }
        end
      end

      def self.build_sheet_display(char)
        EquipmentHelper.migrate_character!(char)
        class_key = char.osr_class
        cfg = Tables.class_config(class_key)
        row = Tables.progression_row(class_key, char.osr_level || 1)
        tradition = char.osr_spell_tradition || Tables.spell_tradition(class_key)
        casting = Tables.casting_type(class_key)
        spell_book = char.osr_spell_book || {}
        spells = tradition ? Tables.spells_for_tradition(tradition) : {}

        details = Tables.class_details(class_key)
        special_abilities = Tables.val(details, 'special_abilities') || []
        thief_display = build_thief_display(char)
        exploration_display = build_exploration_display(char, special_abilities)

        ability_display = Tables.abilities.map do |ab|
          score = char.osr_ability_scores[ab].to_i
          {
            key: ab,
            name: ab.upcase,
            score: score,
            modifier: Tables.ability_modifier(score)
          }
        end

        xp_status = Leveling.xp_status(char)

        {
          class_key: class_key,
          class_name: cfg ? Tables.val(cfg, 'name') : nil,
          race: cfg ? Tables.val(cfg, 'race') : nil,
          group: cfg ? Tables.val(cfg, 'group') : nil,
          level: char.osr_level || 1,
          xp: char.osr_xp || 0,
          xp_bonus: char.osr_xp_bonus || 0,
          max_level: xp_status[:max_level],
          xp_to_next_level: xp_status[:xp_to_next_level],
          can_level_up: xp_status[:can_level_up],
          alignment: char.osr_alignment,
          hd: cfg ? Tables.val(cfg, 'hd') : nil,
          hp: char.osr_hp,
          hp_max: char.osr_hp_max,
          ac: Resources.current_ac(char),
          thac0: char.osr_thac0,
          prepared_spells: Spellcasting.prepared_display(char),
          spell_slots_remaining: Spellcasting.slots_remaining_display(char),
          equipment: EquipmentHelper.gear_display(char),
          inventory: EquipmentHelper.inventory_display(char),
          saves: char.osr_saving_throws,
          spell_slots: char.osr_spell_slots,
          spell_tradition: tradition,
          casting_type: casting,
          spell_book: spell_book,
          expertise_unspent: char.osr_thief_expertise_unspent || 0,
          spells: spells,
          thief_skills: thief_display,
          exploration_skills: exploration_display,
          special_abilities: special_abilities,
          abilities: ability_display,
          starting_gold: char.osr_starting_gold,
          gold: char.osr_gold,
          blurb: cfg ? Tables.val(cfg, 'blurb') : nil,
          playtest: cfg ? Tables.val(cfg, 'playtest') : nil,
          hd_display: row ? Tables.val(row, 'hd') : nil,
          armor: Tables.val(details, 'armor') || (cfg ? Tables.val(cfg, 'armor') : nil),
          weapons: Tables.val(details, 'weapons')
        }
      end

      def self.build_thief_display(char)
        return [] if char.osr_thief_skills.blank?

        base = Tables.base_thief_chance
        char.osr_thief_skills.map do |skill, value|
          chance = if CommandHelpers.sheet_applied?(char)
                     value.to_i
                   else
                     base + value.to_i
                   end
          key = Tables.normalize_key(skill)
          {
            key: key,
            name: key.titleize.gsub('In ', 'in '),
            chance: "#{chance}-in-6"
          }
        end.reject { |sk| EXPLORATION_THIEF_KEYS.include?(sk[:key]) }
      end

      def self.app_review(char)
        lines = []
        sheet = build_sheet_display(char)

        if sheet[:class_name].blank?
          return AresMUSH::Chargen.format_review_status 'OSR Sheet', t('osr_rpg.class_not_set')
        end

        lines << "%xg#{sheet[:class_name]}%xn (#{sheet[:race]}) - Level #{sheet[:level]}"
        lines << "Alignment: #{sheet[:alignment] || 'Not set'}"
        lines << "HP: #{sheet[:hp] || '?'}/#{sheet[:hp_max] || '?'}  THAC0: #{sheet[:thac0] || '?'}  XP Bonus: #{sheet[:xp_bonus]}%"
        lines << "Gold: #{sheet[:gold] || sheet[:starting_gold] || '?'} gp"
        if sheet[:inventory] && sheet[:inventory].any?
          gear = sheet[:inventory].map { |i| i[:qty] > 1 ? "#{i[:name]} x#{i[:qty]}" : i[:name] }.join(', ')
          lines << "Inventory: #{gear}"
        end

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

        if sheet[:casting_type] == 'arcane' && sheet[:spell_book].present?
          l1 = sheet[:spell_book]['1'] || sheet[:spell_book][1] || []
          lines << "Spell book L1: #{l1.join(', ')}" if l1.any?
        elsif sheet[:casting_type] == 'divine' && sheet[:spell_tradition]
          lines << "Divine caster — full #{sheet[:spell_tradition].to_s.titleize} list"
        elsif sheet[:casting_type] == 'restricted' && sheet[:spell_book].present?
          l1 = sheet[:spell_book]['1'] || sheet[:spell_book][1] || []
          lines << "L1 spell: #{l1.join(', ')}" if l1.any?
        end

        if sheet[:thief_skills] && !sheet[:thief_skills].empty?
          skills = sheet[:thief_skills].map { |sk| "#{sk[:name]} #{sk[:chance]}" }.join(', ')
          lines << "Skills: #{skills}"
        end

        roll_count = char.osr_ability_roll_count || 0
        lines << "Ability rolls used: #{roll_count}" if roll_count > 0

        status = lines.join('%r')
        AresMUSH::Chargen.format_review_status 'OSR Sheet', status
      end
    end
  end
end

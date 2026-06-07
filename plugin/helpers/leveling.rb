module AresMUSH
  module OsrRpg
    module Leveling
      def self.can_manage_xp?(actor)
        actor && (actor.has_permission?('admin') || actor.has_permission?('manage_osr_rpg_xp'))
      end

      def self.max_level(class_key)
        cfg = Tables.class_config(class_key)
        return nil unless cfg
        Tables.val(cfg, 'max_level')
      end

      def self.xp_for_level(class_key, level)
        row = Tables.progression_row(class_key, level)
        return nil unless row
        Tables.val(row, 'xp')
      end

      def self.sheet_ready?(char)
        !char.osr_class.blank? && !char.osr_thac0.nil?
      end

      def self.next_level(char)
        current = char.osr_level || 1
        cap = max_level(char.osr_class)
        return nil if cap && current >= cap.to_i
        current + 1
      end

      def self.eligible_for_levelup?(char, bypass_xp: false)
        return t('osr_rpg.no_sheet_for_levelup') unless sheet_ready?(char)

        nxt = next_level(char)
        return t('osr_rpg.at_max_level') if nxt.nil?

        return nil if bypass_xp

        required = xp_for_level(char.osr_class, nxt)
        return t('osr_rpg.no_progression_for_level', level: nxt) if required.nil?

        current_xp = char.osr_xp || 0
        return t('osr_rpg.insufficient_xp', xp: current_xp, required: required) if current_xp < required.to_i

        nil
      end

      def self.apply_prime_xp_bonus?
        Global.read_config('osr_rpg', 'apply_prime_xp_bonus') != false
      end

      def self.adjust_xp_for_bonus(base_amount, bonus_percent)
        (base_amount.to_i * (100 + bonus_percent.to_i) / 100.0).round
      end

      def self.award_xp(char, amount, apply_bonus: nil)
        base = amount.to_i
        bonus_percent = char.osr_xp_bonus || 0

        if base < 0
          awarded = base
        elsif apply_bonus == false || !apply_prime_xp_bonus?
          awarded = base
        else
          awarded = adjust_xp_for_bonus(base, bonus_percent)
        end

        new_total = (char.osr_xp || 0) + awarded
        new_total = 0 if new_total < 0
        char.update(osr_xp: new_total)

        {
          new_total: new_total,
          base: base,
          awarded: awarded,
          bonus_percent: bonus_percent
        }
      end

      def self.apply_level_up(char, bypass_xp: false)
        error = eligible_for_levelup?(char, bypass_xp: bypass_xp)
        return { error: error } if error

        class_key = char.osr_class
        nxt = next_level(char)
        cfg = Tables.class_config(class_key)
        row = Tables.progression_row(class_key, nxt)
        return { error: t('osr_rpg.no_progression_for_level', level: nxt) } unless cfg && row

        con_mod = Tables.con_modifier_for(char)
        hp_added = Tables.hp_gain(Tables.val(cfg, 'hd'), con_mod)
        new_hp_max = (char.osr_hp_max || 0) + hp_added
        new_hp = (char.osr_hp || 0) + hp_added

        updates = {
          osr_level: nxt,
          osr_hp: new_hp,
          osr_hp_max: new_hp_max,
          osr_thac0: Tables.val(row, 'thac0'),
          osr_saving_throws: Tables.val(row, 'saves') || {},
          osr_spell_slots: Tables.val(row, 'spell_slots') || {}
        }

        if Tables.val(cfg, 'skill_system') == 'd6' && nxt > 1
          gained = Tables.expertise_points_for_level(nxt)
          updates[:osr_thief_expertise_unspent] = (char.osr_thief_expertise_unspent || 0) + gained
        end

        char.update(updates)

        {
          level: nxt,
          hp_added: hp_added,
          hp: new_hp,
          hp_max: new_hp_max
        }
      end

      def self.xp_status(char)
        class_key = char.osr_class
        level = char.osr_level || 1
        xp = char.osr_xp || 0
        nxt = next_level(char)
        required = nxt ? xp_for_level(class_key, nxt) : nil
        cap = max_level(class_key)

        {
          level: level,
          xp: xp,
          max_level: cap,
          next_level: nxt,
          xp_to_next_level: required,
          can_level_up: eligible_for_levelup?(char).nil?
        }
      end
    end
  end
end

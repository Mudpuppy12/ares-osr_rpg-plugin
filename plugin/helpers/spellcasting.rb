module AresMUSH
  module OsrRpg
    module Spellcasting
      def self.normalize_spell_name(name)
        name.to_s.strip.titleize
      end

      def self.spell_level_for(char, spell_name)
        tradition = char.osr_spell_tradition || Tables.spell_tradition(char.osr_class)
        return nil if tradition.blank?

        name = normalize_spell_name(spell_name)
        lists = Tables.spells_for_tradition(tradition)
        lists.each do |lvl, spells|
          return lvl.to_i if Array(spells).map(&:to_s).include?(name)
        end
        nil
      end

      def self.available_slots(char, level)
        max_slots = char.osr_spell_slots || {}
        used = char.osr_spell_slots_used || {}
        max = (max_slots[level.to_s] || max_slots[level.to_i] || 0).to_i
        used_count = (used[level.to_s] || used[level.to_i] || 0).to_i
        [max - used_count, 0].max
      end

      def self.prepared_spells(char)
        char.osr_prepared_spells || {}
      end

      def self.prepare_spell(char, spell_name)
        casting = Tables.casting_type(char.osr_class)
        return { error: t('osr_rpg.spell_info_none') } if casting.nil?

        level = spell_level_for(char, spell_name)
        return { error: t('osr_rpg.invalid_spell', spell: spell_name) } if level.nil?

        if casting == 'arcane'
          book = char.osr_spell_book || {}
          lvl_book = book[level.to_s] || book[level.to_i] || []
          unless Array(lvl_book).map(&:to_s).include?(normalize_spell_name(spell_name))
            return { error: t('osr_rpg.spell_not_in_book', spell: spell_name) }
          end
        end

        return { error: t('osr_rpg.no_spell_slots', level: level) } if available_slots(char, level) <= 0

        prep = prepared_spells(char).dup
        list = Array(prep[level.to_s] || prep[level.to_i]).dup
        name = normalize_spell_name(spell_name)
        return { error: t('osr_rpg.spell_already_prepared', spell: name) } if list.include?(name)

        list << name
        prep[level.to_s] = list
        char.update(osr_prepared_spells: prep)
        { spell: name, level: level, prepared: list }
      end

      def self.cast_spell(char, spell_name)
        name = normalize_spell_name(spell_name)
        prep = prepared_spells(char).dup
        found_level = nil
        prep.each do |lvl, spells|
          if Array(spells).map(&:to_s).include?(name)
            found_level = lvl
            break
          end
        end
        return { error: t('osr_rpg.spell_not_prepared', spell: name) } unless found_level

        list = Array(prep[found_level]).dup
        list.delete(name)
        prep[found_level] = list
        prep.delete(found_level) if list.empty?

        used = (char.osr_spell_slots_used || {}).dup
        used[found_level.to_s] = (used[found_level.to_s] || used[found_level.to_i] || 0).to_i + 1
        char.update(osr_prepared_spells: prep, osr_spell_slots_used: used)
        { spell: name, level: found_level.to_i }
      end

      def self.rest_spells(char)
        char.update(osr_prepared_spells: {}, osr_spell_slots_used: {})
        true
      end

      def self.learn_spell_on_levelup(char, level, spell_name)
        return { error: t('osr_rpg.spell_info_none') } unless Tables.casting_type(char.osr_class) == 'arcane'

        lvl = level.to_i
        tradition = char.osr_spell_tradition || Tables.spell_tradition(char.osr_class)
        valid = (Tables.spells_for_tradition(tradition)[lvl.to_s] || []).map(&:to_s)
        name = normalize_spell_name(spell_name)
        return { error: t('osr_rpg.invalid_spell', spell: spell_name) } unless valid.include?(name)

        book = (char.osr_spell_book || {}).dup
        list = Array(book[lvl.to_s] || book[lvl.to_i]).dup
        return { error: t('osr_rpg.duplicate_spell_pick') } if list.include?(name)

        list << name
        book[lvl.to_s] = list
        char.update(osr_spell_book: book)
        { spell: name, level: lvl }
      end

      def self.prepared_display(char)
        prepared_spells(char).map do |lvl, spells|
          { level: lvl, spells: Array(spells) }
        end
      end

      def self.slots_remaining_display(char)
        slots = char.osr_spell_slots || {}
        slots.each_with_object({}) do |(lvl, max), h|
          h[lvl] = available_slots(char, lvl)
        end
      end
    end
  end
end

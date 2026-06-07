module AresMUSH
  module OsrRpg
    module ReferenceData
      TRADITION_LABELS = {
        'cleric' => 'Cleric',
        'druid' => 'Druid',
        'magic_user' => 'Magic-User',
        'illusionist' => 'Illusionist',
        'necromancer' => 'Necromancer'
      }.freeze

      def self.spell_details_config
        Global.read_config('osr', 'spell_details') || {}
      end

      def self.spells_for_web(tradition = nil)
        all_spells = Global.read_config('osr', 'spells') || {}
        tradition_keys = all_spells.keys.map(&:to_s).sort
        selected = tradition.present? ? tradition.to_s : tradition_keys.first
        blurb = Global.read_config('osr_rpg', 'spells_blurb')

        {
          traditions: tradition_keys.map { |t| { key: t, name: tradition_label(t) } },
          tradition: selected,
          spells_by_level: build_spells_by_level(all_spells, selected),
          spells_blurb: blurb.blank? ? nil : Website.format_markdown_for_html(blurb)
        }
      end

      def self.spell_detail_for_web(tradition, level, name)
        key = Tables.spell_detail_key(name)
        entry = Tables.spell_detail(tradition, level, key)
        return { error: t('osr_rpg.spell_not_found') } unless entry

        desc = format_spell_text(entry['description'] || entry[:description])
        reversal = format_spell_text(entry['reversal'] || entry[:reversal])
        {
          name: entry['name'] || entry[:name] || name,
          key: key,
          level: level.to_s,
          tradition: tradition.to_s,
          tradition_name: tradition_label(tradition),
          description: desc,
          reversal: reversal,
          description_html: Website.format_markdown_for_html(desc),
          reversal_html: reversal.blank? ? nil : Website.format_markdown_for_html(reversal)
        }
      end

      def self.equipment_for_web
        catalog = Global.read_config('osr', 'equipment') || {}
        blurb = Global.read_config('osr_rpg', 'equipment_blurb')

        {
          armor: build_equipment_list(catalog['armor'], sort_by_ac: true),
          weapons: build_equipment_list(catalog['weapons']),
          missile_weapons: build_equipment_list(catalog['missile_weapons']),
          adventuring_gear: build_equipment_list(catalog['adventuring_gear']),
          equipment_blurb: blurb.blank? ? nil : Website.format_markdown_for_html(blurb)
        }
      end

      def self.build_spells_by_level(all_spells, tradition)
        return [] if tradition.blank?

        levels = all_spells[tradition] || all_spells[tradition.to_sym] || {}
        levels.sort_by { |lvl, _| lvl.to_i }.map do |level, names|
          {
            level: level.to_s,
            spells: Array(names).map do |spell_name|
              key = Tables.spell_detail_key(spell_name)
              {
                name: spell_name,
                key: key,
                level: level.to_s,
                tradition: tradition.to_s
              }
            end
          }
        end
      end

      def self.build_equipment_list(hash, sort_by_ac: false)
        return [] unless hash

        rows = hash.map do |key, data|
          entry = data.is_a?(Hash) ? data : {}
          {
            key: key.to_s,
            name: entry['name'] || key.to_s.titleize,
            cost: entry['cost'],
            damage: entry['damage'],
            ac: entry['ac'],
            ac_bonus: entry['ac_bonus'],
            notes: entry['notes']
          }
        end

        if sort_by_ac
          rows.sort_by { |row| [row[:ac].nil? ? 999 : row[:ac].to_i, row[:name].to_s.downcase] }
        else
          rows.sort_by { |row| row[:name].to_s.downcase }
        end
      end

      def self.tradition_label(tradition)
        TRADITION_LABELS[tradition.to_s] || tradition.to_s.titleize.gsub('_', ' ')
      end

      def self.format_spell_text(text)
        return text if text.blank?

        text.to_s.strip.sub(/\A([a-z])/) { Regexp.last_match(1).upcase }
      end
    end
  end
end

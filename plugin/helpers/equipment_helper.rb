module AresMUSH
  module OsrRpg
    module EquipmentHelper
      def self.catalog
        Global.read_config('osr', 'equipment') || {}
      end

      def self.equip_item(char, item_key)
        key = Tables.normalize_key(item_key)
        armor = catalog['armor'] || {}
        weapons = catalog['weapons'] || {}
        unless armor[key] || armor[key.to_sym] || weapons[key] || weapons[key.to_sym]
          return { error: t('osr_rpg.invalid_equipment', item: item_key) }
        end

        list = (char.osr_equipment || []).dup
        list << key unless list.include?(key)
        suggested_ac = suggest_ac_for_list(list)
        char.update(osr_equipment: list, osr_ac: suggested_ac)
        { equipment: list, ac: suggested_ac }
      end

      def self.unequip_item(char, item_key)
        key = Tables.normalize_key(item_key)
        list = (char.osr_equipment || []).dup
        list.delete(key)
        suggested_ac = list.empty? ? CommandHelpers.default_ac : suggest_ac_for_list(list)
        char.update(osr_equipment: list, osr_ac: suggested_ac)
        { equipment: list, ac: suggested_ac }
      end

      def self.suggest_ac_for_list(equipment)
        armor_catalog = self.catalog['armor'] || {}
        ac = CommandHelpers.default_ac
        bonus = 0
        equipment.each do |item|
          key = Tables.normalize_key(item)
          entry = armor_catalog[key] || armor_catalog[key.to_sym]
          next unless entry
          if entry['ac']
            ac = [entry['ac'].to_i, ac].min
          elsif entry['ac_bonus']
            bonus += entry['ac_bonus'].to_i
          end
        end
        [ac + bonus, 1].max
      end

      def self.gear_display(char)
        list = char.osr_equipment || []
        catalog = self.catalog
        list.map do |key|
          armor = catalog.dig('armor', key) || catalog.dig('armor', key.to_sym)
          weapon = catalog.dig('weapons', key) || catalog.dig('weapons', key.to_sym)
          entry = armor || weapon || {}
          { key: key, name: entry['name'] || key.titleize }
        end
      end
    end
  end
end

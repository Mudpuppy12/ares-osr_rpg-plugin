module AresMUSH
  module OsrRpg
    module ShopHelper
      MAGIC_CATEGORIES = %w[magic_consumables magic_scrolls].freeze
      BUY_EXCLUDE_KEYS = %w[none].freeze

      def self.shop_config
        {
          'magic_consumables' => Global.read_config('osr_rpg', 'magic_consumables') || {},
          'magic_scrolls' => Global.read_config('osr_rpg', 'magic_scrolls') || {}
        }
      end

      def self.eligible?(char)
        char.is_approved? && Leveling.sheet_ready?(char)
      end

      def self.eligibility_error(char)
        return t('osr_rpg.shop_not_eligible') unless char.is_approved?
        return t('osr_rpg.no_sheet_for_levelup') unless Leveling.sheet_ready?(char)

        nil
      end

      def self.arcane_caster?(char)
        class_key = char.osr_class
        return false if class_key.blank?

        Tables.casting_type(class_key) == 'arcane'
      end

      def self.lookup_magic_item(item_key)
        key = Tables.normalize_key(item_key)
        shop_config.each do |category, items|
          entry = items[key] || items[key.to_sym]
          next unless entry

          return {
            key: key,
            category: category,
            name: entry['name'] || key.titleize,
            cost: entry['cost'].to_i,
            notes: entry['notes'],
            spell: entry['spell'],
            level: entry['level'],
            arcane_only: entry['arcane_only'] == true || entry['arcane_only'].to_s == 'true'
          }
        end
        nil
      end

      def self.can_buy_item?(char, item)
        return true unless item[:arcane_only]

        arcane_caster?(char)
      end

      def self.buy_item(char, item_key, qty = 1)
        error = eligibility_error(char)
        return { error: error } if error

        item = EquipmentHelper.lookup_item(item_key)
        return { error: t('osr_rpg.invalid_equipment', item: item_key) } unless item
        return { error: t('osr_rpg.shop_scroll_arcane_only') } unless can_buy_item?(char, item)

        EquipmentHelper.buy_item(char, item_key, qty)
      end

      def self.sell_item(char, item_key, qty = 1)
        error = eligibility_error(char)
        return { error: error } if error

        EquipmentHelper.sell_item(char, item_key, qty)
      end

      def self.build_magic_list(category, items)
        return [] unless items

        items.map do |key, data|
          entry = data.is_a?(Hash) ? data : {}
          {
            key: key.to_s,
            name: entry['name'] || key.to_s.titleize,
            cost: entry['cost'].to_i,
            notes: entry['notes'],
            spell: entry['spell'],
            level: entry['level'],
            arcane_only: entry['arcane_only'] == true || entry['arcane_only'].to_s == 'true'
          }
        end.sort_by { |row| row[:name].to_s.downcase }
      end

      def self.filter_buy_items(items)
        items.reject do |item|
          key = item[:key] || item['key']
          cost = (item[:cost] || item['cost']).to_i
          BUY_EXCLUDE_KEYS.include?(key.to_s) || cost <= 0
        end
      end

      def self.catalog_for_web(_char)
        equipment = ReferenceData.equipment_for_web
        magic = shop_config

        [
          { key: 'armor', title: 'Armor', items: filter_buy_items(equipment[:armor] || []) },
          { key: 'weapons', title: 'Melee Weapons', items: filter_buy_items(equipment[:weapons] || []) },
          { key: 'missile_weapons', title: 'Missile Weapons', items: filter_buy_items(equipment[:missile_weapons] || []) },
          { key: 'adventuring_gear', title: 'Adventuring Gear', items: filter_buy_items(equipment[:adventuring_gear] || []) },
          { key: 'magic_consumables', title: 'Potions', items: build_magic_list('magic_consumables', magic['magic_consumables']) },
          { key: 'magic_scrolls', title: 'Arcane Scrolls', items: build_magic_list('magic_scrolls', magic['magic_scrolls']) }
        ].reject { |section| section[:items].empty? }
      end

      def self.sellable_inventory(char)
        EquipmentHelper.inventory_display(char).map do |row|
          row.merge(sell_value: row[:cost].to_i / 2)
        end
      end

      def self.state_for_web(char)
        EquipmentHelper.migrate_character!(char)
        error = eligibility_error(char)
        blurb = Global.read_config('osr_rpg', 'shop_blurb')

        if error
          return {
            eligible: false,
            message: error,
            shop_blurb: blurb.blank? ? nil : Website.format_markdown_for_html(blurb)
          }
        end

        {
          eligible: true,
          gold: char.osr_gold || 0,
          arcane_caster: arcane_caster?(char),
          catalog_sections: catalog_for_web(char),
          inventory: sellable_inventory(char),
          equipment: EquipmentHelper.gear_display(char),
          shop_blurb: blurb.blank? ? nil : Website.format_markdown_for_html(blurb)
        }
      end

      def self.response_after_transaction(char, result)
        return result if result[:error]

        state = state_for_web(char)
        result.merge(
          gold: char.osr_gold,
          inventory: state[:inventory],
          equipment: state[:equipment],
          message: result[:message]
        )
      end
    end
  end
end

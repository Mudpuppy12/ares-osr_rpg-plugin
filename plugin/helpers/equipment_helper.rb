module AresMUSH
  module OsrRpg
    module EquipmentHelper
      CATALOG_CATEGORIES = %w[armor weapons missile_weapons adventuring_gear].freeze
      EQUIPPABLE_CATEGORIES = %w[armor weapons].freeze
      ARMOR_BODY_KEYS = %w[leather chain plate].freeze

      def self.catalog
        Global.read_config('osr', 'equipment') || {}
      end

      def self.lookup_item(item_key)
        key = Tables.normalize_key(item_key)
        CATALOG_CATEGORIES.each do |category|
          items = catalog[category] || {}
          entry = items[key] || items[key.to_sym]
          next unless entry

          return build_lookup_entry(key, category, entry)
        end

        magic = ShopHelper.lookup_magic_item(key)
        return magic if magic

        nil
      end

      def self.build_lookup_entry(key, category, entry)
        {
          key: key,
          category: category,
          name: entry['name'] || key.titleize,
          cost: entry['cost'].to_i,
          damage: entry['damage'],
          ac: entry['ac'],
          ac_bonus: entry['ac_bonus'],
          notes: entry['notes']
        }
      end

      def self.equippable?(item_key)
        item = lookup_item(item_key)
        item && EQUIPPABLE_CATEGORIES.include?(item[:category])
      end

      def self.normalize_inventory_hash(raw)
        (raw || {}).each_with_object({}) do |(key, qty), h|
          norm = Tables.normalize_key(key)
          count = qty.to_i
          next if count <= 0

          h[norm] = count
        end
      end

      def self.inventory_qty(char, item_key)
        key = Tables.normalize_key(item_key)
        inv = normalize_inventory_hash(char.osr_inventory)
        inv[key] || 0
      end

      def self.cart_total(inventory_hash)
        normalize_inventory_hash(inventory_hash).sum do |key, qty|
          item = lookup_item(key)
          next 0 unless item

          item[:cost] * qty
        end
      end

      def self.migrate_character!(char)
        updates = {}
        inv = normalize_inventory_hash(char.osr_inventory)
        equipped = (char.osr_equipment || []).map { |k| Tables.normalize_key(k) }
        unique_equipped = equipped.uniq
        if unique_equipped != equipped
          updates[:osr_equipment] = unique_equipped
          equipped = unique_equipped
        end

        cleaned = inv.dup
        equipped.each do |key|
          next unless cleaned[key]

          cleaned[key] -= 1
          cleaned.delete(key) if cleaned[key] <= 0
        end
        if cleaned != inv
          updates[:osr_inventory] = cleaned
          inv = cleaned
        end

        if char.osr_gold.nil? && char.osr_starting_gold
          updates[:osr_gold] = char.osr_starting_gold
        end

        if equipped.any?
          expected = suggest_ac_for_list(equipped)
          stored = char.osr_ac
          baseline = CommandHelpers.ac_baseline
          if stored.nil? || stored.to_i == baseline - expected
            updates[:osr_ac] = expected unless stored.to_i == expected
          end
        end

        char.update(updates) if updates.any?
        char
      end

      def self.add_to_inventory(char, item_key, qty = 1)
        key = Tables.normalize_key(item_key)
        inv = normalize_inventory_hash(char.osr_inventory)
        inv[key] = (inv[key] || 0) + qty.to_i
        char.update(osr_inventory: inv)
        inv
      end

      def self.remove_from_inventory(char, item_key, qty = 1)
        key = Tables.normalize_key(item_key)
        inv = normalize_inventory_hash(char.osr_inventory)
        current = inv[key] || 0
        return { error: t('osr_rpg.inventory_not_owned', item: item_key) } if current < qty.to_i

        new_qty = current - qty.to_i
        if new_qty <= 0
          inv.delete(key)
        else
          inv[key] = new_qty
        end
        char.update(osr_inventory: inv)
        inv
      end

      def self.buy_item(char, item_key, qty = 1)
        qty = [qty.to_i, 1].max
        item = lookup_item(item_key)
        return { error: t('osr_rpg.invalid_equipment', item: item_key) } unless item

        cost = item[:cost] * qty
        gold = char.osr_gold || 0
        return { error: t('osr_rpg.insufficient_gold', cost: cost, gold: gold) } if gold < cost

        char.update(osr_gold: gold - cost)
        add_to_inventory(char, item[:key], qty)
        {
          item: item[:name],
          qty: qty,
          cost: cost,
          gold: char.osr_gold,
          inventory: normalize_inventory_hash(char.osr_inventory)
        }
      end

      def self.sell_item(char, item_key, qty = 1)
        qty = [qty.to_i, 1].max
        item = lookup_item(item_key)
        return { error: t('osr_rpg.invalid_equipment', item: item_key) } unless item

        equipped = (char.osr_equipment || []).map { |k| Tables.normalize_key(k) }
        key = Tables.normalize_key(item_key)
        return { error: t('osr_rpg.cannot_sell_equipped', item: item[:name]) } if equipped.include?(key)

        result = remove_from_inventory(char, key, qty)
        return result if result[:error]

        credit = (item[:cost] * qty) / 2
        char.update(osr_gold: (char.osr_gold || 0) + credit)
        {
          item: item[:name],
          qty: qty,
          gold: char.osr_gold,
          credit: credit,
          inventory: normalize_inventory_hash(char.osr_inventory)
        }
      end

      def self.merge_equipped_into_inventory(char, inventory_hash)
        inv = normalize_inventory_hash(inventory_hash)
        (char.osr_equipment || []).each do |item|
          key = Tables.normalize_key(item)
          next if (inv[key] || 0).positive?

          inv[key] = 1
        end
        inv
      end

      def self.purchase_items(char, inventory_hash, budget:)
        inv = normalize_inventory_hash(inventory_hash)
        total = cart_total(inv)
        return { error: t('osr_rpg.insufficient_gold', cost: total, gold: budget) } if total > budget.to_i

        inv.each_key do |key|
          return { error: t('osr_rpg.invalid_equipment', item: key) } unless lookup_item(key)
        end

        {
          inventory: inv,
          gold_spent: total,
          gold_remaining: budget.to_i - total
        }
      end

      def self.equip_item(char, item_key)
        key = Tables.normalize_key(item_key)
        return { error: t('osr_rpg.invalid_equipment', item: item_key) } unless equippable?(key)
        return { error: t('osr_rpg.inventory_not_owned', item: item_key) } if inventory_qty(char, key) < 1

        list = (char.osr_equipment || []).map { |k| Tables.normalize_key(k) }
        unless list.include?(key)
          remove_from_inventory(char, key, 1)
          list << key
        end

        suggested_ac = suggest_ac_for_list(list)
        char.update(osr_equipment: list, osr_ac: suggested_ac)
        { equipment: list, ac: suggested_ac }
      end

      def self.unequip_item(char, item_key)
        key = Tables.normalize_key(item_key)
        list = (char.osr_equipment || []).map { |k| Tables.normalize_key(k) }
        return { error: t('osr_rpg.not_equipped', item: item_key) } unless list.include?(key)

        list.delete(key)
        add_to_inventory(char, key, 1)
        suggested_ac = list.empty? ? CommandHelpers.default_ac : suggest_ac_for_list(list)
        char.update(osr_equipment: list, osr_ac: suggested_ac)
        { equipment: list, ac: suggested_ac }
      end

      def self.suggest_ac_for_list(equipment)
        armor_catalog = catalog['armor'] || {}
        ac = CommandHelpers.default_ac
        bonus = 0
        equipment.each do |item|
          key = Tables.normalize_key(item)
          entry = armor_catalog[key] || armor_catalog[key.to_sym]
          next unless entry
          if entry['ac']
            ac = [entry['ac'].to_i, ac].max
          elsif entry['ac_bonus']
            bonus += entry['ac_bonus'].to_i
          end
        end
        ac + bonus
      end

      def self.auto_equip_from_inventory(char)
        inv = normalize_inventory_hash(char.osr_inventory)
        equipped = []

        best_armor = nil
        best_ac = CommandHelpers.default_ac - 1
        ARMOR_BODY_KEYS.each do |armor_key|
          next unless (inv[armor_key] || 0).positive?

          entry = catalog.dig('armor', armor_key) || catalog.dig('armor', armor_key.to_sym)
          next unless entry

          ac_val = entry['ac'].to_i
          if ac_val > best_ac
            best_ac = ac_val
            best_armor = armor_key
          end
        end

        if best_armor
          equipped << best_armor
          inv[best_armor] -= 1
          inv.delete(best_armor) if inv[best_armor] <= 0
        end

        if (inv['shield'] || 0).positive?
          equipped << 'shield'
          inv['shield'] -= 1
          inv.delete('shield') if inv['shield'] <= 0
        end

        weapons = catalog['weapons'] || {}
        weapon_key = inv.keys.find { |k| weapons[k] || weapons[k.to_sym] }
        if weapon_key
          equipped << weapon_key
          inv[weapon_key] -= 1
          inv.delete(weapon_key) if inv[weapon_key] <= 0
        end

        ac = equipped.empty? ? CommandHelpers.default_ac : suggest_ac_for_list(equipped)
        char.update(osr_equipment: equipped, osr_inventory: inv, osr_ac: ac)
        { equipment: equipped, ac: ac, inventory: inv }
      end

      def self.inventory_display(char)
        normalize_inventory_hash(char.osr_inventory).map do |key, qty|
          item = lookup_item(key)
          next unless item

          {
            key: key,
            name: item[:name],
            qty: qty,
            cost: item[:cost],
            category: item[:category],
            equippable: equippable?(key)
          }
        end.compact.sort_by { |row| row[:name].to_s.downcase }
      end

      def self.gear_display(char)
        list = char.osr_equipment || []
        list.map do |key|
          item = lookup_item(key)
          {
            key: Tables.normalize_key(key),
            name: item ? item[:name] : key.to_s.titleize
          }
        end
      end

      def self.class_equipment_notes(class_key)
        return nil if class_key.blank?

        details = Tables.class_details(class_key)
        armor = Tables.val(details, 'armor')
        weapons = Tables.val(details, 'weapons')
        return nil if armor.blank? && weapons.blank?

        parts = []
        parts << "Armor: #{armor}" if armor.present?
        parts << "Weapons: #{weapons}" if weapons.present?
        parts.join(' · ')
      end
    end
  end
end

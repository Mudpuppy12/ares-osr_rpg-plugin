module AresMUSH
  module OsrRpg
    module Resources
      def self.adjust_hp(char, amount)
        cur = char.osr_hp || 0
        max = char.osr_hp_max || cur
        new_hp = cur + amount.to_i
        new_hp = 0 if new_hp < 0
        new_hp = max if new_hp > max
        char.update(osr_hp: new_hp)
        { hp: new_hp, hp_max: max, delta: amount.to_i }
      end

      def self.set_hp(char, current, maximum = nil)
        max = maximum.nil? ? (char.osr_hp_max || current.to_i) : maximum.to_i
        cur = current.to_i
        cur = 0 if cur < 0
        cur = max if cur > max
        char.update(osr_hp: cur, osr_hp_max: max)
        { hp: cur, hp_max: max }
      end

      def self.set_ac(char, value)
        ac = value.to_i
        char.update(osr_ac: ac)
        ac
      end

      def self.current_ac(char)
        char.osr_ac.nil? ? CommandHelpers.default_ac : char.osr_ac
      end

      def self.suggest_ac_from_equipment(char)
        equipment = char.osr_equipment || []
        catalog = Global.read_config('osr', 'equipment', 'armor') || {}
        ac = CommandHelpers.default_ac
        bonus = 0
        equipment.each do |item|
          key = Tables.normalize_key(item)
          entry = catalog[key] || catalog[key.to_sym]
          next unless entry
          if entry['ac']
            ac = [entry['ac'].to_i, ac].min
          elsif entry['ac_bonus']
            bonus += entry['ac_bonus'].to_i
          end
        end
        [ac + bonus, 1].max
      end
    end
  end
end
